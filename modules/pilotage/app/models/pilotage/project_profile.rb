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
  class ProjectProfile < ApplicationRecord
    CLASSES = OpenProject::Pilotage::Defaults::CLASSES
    HEALTH = OpenProject::Pilotage::Defaults::HEALTH
    PHASES = OpenProject::Pilotage::Defaults::LIFECYCLE_KEYS

    belongs_to :project, inverse_of: :pilotage_profile
    belongs_to :pilot_entity, class_name: "Pilotage::Entity", optional: true, inverse_of: :project_profiles
    belongs_to :sponsor, class_name: "User", optional: true
    belongs_to :manager, class_name: "User", optional: true
    belongs_to :correspondent, class_name: "User", optional: true

    validates :project_class, inclusion: { in: CLASSES }
    validates :declared_health, inclusion: { in: HEALTH }
    validates :phase, inclusion: { in: PHASES }
    validates :entities_count, numericality: { greater_than_or_equal_to: 1 }
    validates :budget_total, :budget_committed, :budget_spent,
              numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validate :end_after_start

    before_validation :compute_class_if_blank

    scope :of_class, ->(klass) { where(project_class: klass) }

    def budget_consumption_ratio
      return nil if budget_total.blank? || budget_total.zero?

      ((budget_spent || 0) / budget_total * 100).round
    end

    def budget_in_units
      return nil if budget_total.blank?

      budget_total / Setting.pilotage_budget_unit.to_d
    end

    def reporting_cadence_days
      Pilotage::Classification.cadence_days(project_class)
    end

    def phase_index
      PHASES.index(phase) || 0
    end

    def phase_label
      Pilotage::Lifecycle.label(category, phase)
    end

    def schedule_variance_days
      return nil if end_on.blank? || baseline_end_on.blank?

      (end_on - baseline_end_on).to_i
    end

    private

    def end_after_start
      return if start_on.blank? || end_on.blank?

      errors.add(:end_on, :greater_than_start_date) if end_on < start_on
    end

    def compute_class_if_blank
      return if project_class.present? && !project_class_changed?
      return if budget_total.blank?

      self.project_class = Pilotage::Classification.classify(budget_total:, entities_count:)
    end
  end
end
