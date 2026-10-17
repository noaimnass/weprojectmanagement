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
  # Builds the portfolio rows (project + profile + signals) for the user, with filters and groupings.
  class PortfolioSummary
    Row = Struct.new(:project, :profile, :signals, keyword_init: true) do
      def health = signals.computed_health
      def project_class = profile&.project_class || "C"
      def category = profile&.category
      def entity = profile&.pilot_entity
      def phase = profile&.phase || "P0"
    end

    FILTERS = %i[category project_class entity_id health portfolio program axis q].freeze
    GROUPINGS = %w[none category project_class portfolio program entity axis phase].freeze

    attr_reader :rows, :filters, :grouping

    def initialize(user: User.current, filters: {}, grouping: "none", projects: nil)
      @user = user
      @filters = filters.to_h.symbolize_keys.slice(*FILTERS).compact_blank
      @grouping = GROUPINGS.include?(grouping.to_s) ? grouping.to_s : "none"
      @scope = projects
    end

    def call
      projects = base_scope.to_a
      profiles = Pilotage::ProjectProfile.where(project_id: projects.map(&:id)).includes(:pilot_entity, :manager, :sponsor)
                                         .index_by(&:project_id)
      aggregates = Pilotage::Signals.aggregates_for(projects.map(&:id), user: @user)

      @rows = projects.map do |project|
        profile = profiles[project.id]
        signals = Pilotage::Signals.new(project, profile:, aggregates: aggregates[project.id]).call
        Row.new(project:, profile:, signals:)
      end
      @rows = apply_computed_filters(@rows)
      self
    end

    def grouped
      return { nil => rows } if grouping == "none"

      rows.group_by { |row| group_key(row) }.sort_by { |key, _| key.to_s }.to_h
    end

    def group_key(row)
      case grouping
      when "category" then Pilotage::Lifecycle.category_label(row.category)
      when "project_class" then row.project_class
      when "portfolio" then row.profile&.portfolio.presence
      when "program" then row.profile&.program.presence || row.project.parent&.name
      when "entity" then row.entity&.name
      when "axis" then Pilotage::Lifecycle.axis_label(row.profile&.strategic_axis)
      when "phase" then row.phase
      end
    end

    def counts_by_health
      OpenProject::Pilotage::Defaults::HEALTH.index_with { |h| rows.count { |r| r.health == h } }
    end

    def counts_by_class
      OpenProject::Pilotage::Defaults::CLASSES.index_with { |c| rows.count { |r| r.project_class == c } }
    end

    def counts_by_signal(signal)
      OpenProject::Pilotage::Defaults::HEALTH.index_with { |h| rows.count { |r| r.signals.public_send(signal) == h } }
    end

    def false_greens
      rows.select { |r| r.signals.false_green }
    end

    def critical
      rows.select { |r| r.health == "red" }
    end

    def project_ids
      rows.map { |r| r.project.id }
    end

    def average_progress
      values = rows.filter_map { |r| r.signals.progress }
      values.any? ? (values.sum.to_f / values.size).round : nil
    end

    def total_budget
      rows.sum { |r| r.profile&.budget_total || 0 }
    end

    def total_spent
      rows.sum { |r| r.profile&.budget_spent || 0 }
    end

    private

    def base_scope
      scope = (@scope || Project.allowed_to(@user, :view_pilotage)).active.where(templated: false)
      scope = scope.joins(:enabled_modules).where(enabled_modules: { name: "pilotage" })
      scope = scope.includes(:parent, :enabled_modules)
      if filters[:q].present?
        scope = scope.where("LOWER(projects.name) LIKE :q OR LOWER(projects.identifier) LIKE :q", q: "%#{filters[:q].downcase}%")
      end
      profile_filters = filters.slice(:category, :project_class, :portfolio, :program)
      if profile_filters.any? || filters[:entity_id].present? || filters[:axis].present?
        conditions = profile_filters.transform_keys { |k| k == :project_class ? :project_class : k }
        conditions[:strategic_axis] = filters[:axis] if filters[:axis].present?
        if filters[:entity_id].present?
          entity = Pilotage::Entity.find_by(id: filters[:entity_id])
          conditions[:pilot_entity_id] = entity ? entity.self_and_descendant_ids : -1
        end
        scope = scope.joins(:pilotage_profile).where(pilotage_project_profiles: conditions)
      end
      scope.order(:name)
    end

    def apply_computed_filters(rows)
      return rows if filters[:health].blank?

      rows.select { |r| r.health == filters[:health] }
    end
  end
end
