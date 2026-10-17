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
  # The eight indicators measuring the quality of the steering device itself.
  class DeviceIndicators
    Indicator = Struct.new(:key, :value, :unit, :numerator, :denominator, :target, keyword_init: true) do
      def ratio? = unit == "%"
      def on_target?
        return nil if target.nil? || value.nil?

        key == :false_greens || key == :decision_delay ? value <= target : value >= target
      end
    end

    def initialize(summary)
      @summary = summary
      @rows = summary.rows
      @project_ids = summary.project_ids
    end

    def call
      [
        percent(:reporting_up_to_date, @rows.count { |r| r.signals.reporting == "green" }, @rows.size, 90),
        percent(:validations_in_time, validations_in_time, validated_reports.size, 90),
        percent(:milestones_held, held_milestones.count(&:held_on_time?), held_milestones.size, 80),
        percent(:financial_ref, class_a.count { |r| r.profile&.financial_ref.present? }, class_a.size, 100),
        percent(:benefits_measured, class_a.count { |r| measured_benefit_project_ids.include?(r.project.id) }, class_a.size, 100),
        Indicator.new(key: :false_greens, value: @summary.false_greens.size, unit: "", target: 0),
        Indicator.new(key: :decision_delay, value: average_decision_delay, unit: "d", target: 30),
        percent(:correspondents, @rows.count { |r| r.profile&.correspondent_id.present? }, @rows.size, 100)
      ]
    end

    private

    def percent(key, numerator, denominator, target)
      value = denominator.positive? ? (numerator * 100.0 / denominator).round : nil
      Indicator.new(key:, value:, unit: "%", numerator:, denominator:, target:)
    end

    def class_a
      @class_a ||= @rows.select { |r| r.project_class == "A" }
    end

    def validated_reports
      @validated_reports ||= Pilotage::StatusReport.where(project_id: @project_ids).validated.to_a
    end

    def validations_in_time
      validated_reports.count { |r| r.validation_delay_days && r.validation_delay_days <= 2 }
    end

    def held_milestones
      @held_milestones ||= Pilotage::MilestoneReview.where(project_id: @project_ids).where.not(actual_on: nil).to_a
    end

    def measured_benefit_project_ids
      @measured_benefit_project_ids ||= Pilotage::RegisterItem.where(project_id: @project_ids, kind: "benefit")
                                                              .where("details->>'measured_value' IS NOT NULL AND details->>'measured_value' <> ''")
                                                              .distinct.pluck(:project_id)
    end

    def average_decision_delay
      delays = Pilotage::ProjectRequest.where.not(decided_at: nil).where.not(submitted_at: nil)
                                       .filter_map(&:decision_delay_days)
      delays.any? ? (delays.sum.to_f / delays.size).round : nil
    end
  end
end
