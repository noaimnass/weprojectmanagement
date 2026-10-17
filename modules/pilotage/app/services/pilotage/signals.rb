# frozen_string_literal: true

#-- copyright
# WeProjectManagement — Pilotage module, by WeWorld Tech (weworld.tech).
# Copyright (C) WeWorld Tech
#
# WeProjectManagement is a derivative work of OpenProject.
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++
module Pilotage
  # Computes the steering signals of one project from its milestones, work packages,
  # risk register, budget and reporting discipline. Rules are documented in the Reference page.
  class Signals
    LEVELS = OpenProject::Pilotage::Defaults::HEALTH

    Result = Struct.new(:schedule, :budget, :risk, :reporting, :computed_health, :declared_health,
                        :false_green, :progress, :details, keyword_init: true) do
      def worst(*levels)
        levels.compact.max_by { |l| LEVELS.index(l) } || "green"
      end
    end

    # Aggregates per project id, computed in bulk by PortfolioSummary to avoid N+1 queries.
    Aggregates = Struct.new(:open_count, :overdue_count, :progress, :max_criticality, :last_validated_at,
                            :late_milestone_days, :declared_health, keyword_init: true)

    def self.aggregates_for(project_ids, user: User.current)
      today = Date.current
      wps = WorkPackage.where(project_id: project_ids)
      open_counts = wps.with_status_open.group(:project_id).count
      overdue_counts = wps.with_status_open.where(due_date: ...today).group(:project_id).count
      progress = wps.group(:project_id).average(Arel.sql("COALESCE(derived_done_ratio, done_ratio, 0)"))
      criticality = Pilotage::RegisterItem.where(project_id: project_ids, kind: "risk").open_items
                                          .where.not(probability: nil).where.not(impact: nil)
                                          .group(:project_id).maximum(Arel.sql("probability * impact"))
      validated = Pilotage::StatusReport.where(project_id: project_ids).validated.group(:project_id).maximum(:validated_at)
      declared = Pilotage::StatusReport.where(project_id: project_ids).validated
                                       .select("DISTINCT ON (project_id) project_id, health")
                                       .order(:project_id, period_end: :desc, id: :desc)
                                       .to_h { |r| [r.project_id, r.health] }
      late_days = Pilotage::MilestoneReview.where(project_id: project_ids).late
                                           .group(:project_id).minimum(:planned_on)
                                           .transform_values { |d| (today - d).to_i }

      project_ids.index_with do |id|
        Aggregates.new(open_count: open_counts[id] || 0,
                       overdue_count: overdue_counts[id] || 0,
                       progress: progress[id]&.round,
                       max_criticality: criticality[id],
                       last_validated_at: validated[id],
                       late_milestone_days: late_days[id] || 0,
                       declared_health: declared[id])
      end
    end

    def initialize(project, profile: nil, aggregates: nil, today: Date.current)
      @project = project
      @profile = profile || project.pilotage_profile
      @aggregates = aggregates || self.class.aggregates_for([project.id])[project.id]
      @today = today
    end

    def call
      schedule = schedule_signal
      budget = budget_signal
      risk = risk_signal
      reporting = reporting_signal
      declared = @aggregates.declared_health || @profile&.declared_health || "green"

      result = Result.new(schedule:, budget:, risk:, reporting:, declared_health: declared,
                          progress: @aggregates.progress, details: @details || {})
      result.computed_health = result.worst(schedule, budget, risk, reporting)
      result.false_green = declared == "green" && result.computed_health == "red"
      result
    end

    private

    def note(key, value)
      (@details ||= {})[key] = value
    end

    def schedule_signal
      late_days = @aggregates.late_milestone_days
      overdue_ratio = @aggregates.open_count.positive? ? @aggregates.overdue_count.to_f / @aggregates.open_count : 0
      variance = @profile&.schedule_variance_days
      variance_ratio = if variance && @profile.start_on && @profile.baseline_end_on
                         duration = (@profile.baseline_end_on - @profile.start_on).to_i
                         duration.positive? ? variance.to_f / duration : 0
                       else
                         0
                       end
      note(:late_milestone_days, late_days)
      note(:overdue_ratio, (overdue_ratio * 100).round)
      note(:schedule_variance_days, variance)

      if late_days > 15 || variance_ratio > 0.10 || overdue_ratio > 0.40
        "red"
      elsif late_days.positive? || variance_ratio > 0.0 || overdue_ratio > 0.20
        "amber"
      else
        "green"
      end
    end

    def budget_signal
      total, spent = budget_figures
      note(:budget_total, total)
      note(:budget_spent, spent)
      return "green" if total.blank? || total.zero?

      consumption = (spent.to_d / total * 100).round
      progress = @aggregates.progress || @profile&.phase_index.to_i * 100 / 8
      note(:budget_consumption, consumption)

      if consumption >= 100 || consumption > progress + 20
        "red"
      elsif consumption >= 90 || consumption > progress + 10
        "amber"
      else
        "green"
      end
    end

    def budget_figures
      if @project.respond_to?(:budgets) && @project.module_enabled?(:budgets)
        budgets = @project.budgets.to_a
        return [budgets.sum(&:budget), budgets.sum(&:spent)] if budgets.any?
      end
      [@profile&.budget_total, @profile&.budget_spent]
    end

    def risk_signal
      criticality = @aggregates.max_criticality
      note(:max_criticality, criticality)
      case criticality
      when nil then "green"
      when 16.. then "red"
      when 10..15 then "amber"
      else "green"
      end
    end

    def reporting_signal
      cadence = Pilotage::Classification.cadence_days(@profile&.project_class || "C")
      last = @aggregates.last_validated_at
      note(:last_validated_at, last)
      return "red" if last.nil?

      age = (@today - last.to_date).to_i
      note(:report_age_days, age)
      if age > cadence * 2
        "red"
      elsif age > cadence
        "amber"
      else
        "green"
      end
    end
  end
end
