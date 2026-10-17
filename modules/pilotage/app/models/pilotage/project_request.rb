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
  class ProjectRequest < ApplicationRecord
    STATES = %w[draft submitted qualified go no_go converted].freeze

    belongs_to :requester, class_name: "User", optional: true
    belongs_to :entity, class_name: "Pilotage::Entity", optional: true, inverse_of: :project_requests
    belongs_to :qualified_by, class_name: "User", optional: true
    belongs_to :project, optional: true

    validates :title, presence: true, length: { maximum: 255 }
    validates :state, inclusion: { in: STATES }
    validates :entities_count, numericality: { greater_than_or_equal_to: 1 }
    validates :estimated_budget, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :estimated_duration_months, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    scope :pending, -> { where(state: %w[submitted qualified]) }
    scope :recent_first, -> { order(created_at: :desc) }

    def eligibility
      Pilotage::Classification.eligibility(budget: estimated_budget,
                                          months: estimated_duration_months,
                                          entities: entities_count)
    end

    def eligible?
      eligibility.values.any?
    end

    def suggested_class
      Pilotage::Classification.classify(budget_total: estimated_budget, entities_count:)
    end

    def decision_delay_days
      return nil if submitted_at.blank? || decided_at.blank?

      ((decided_at - submitted_at) / 1.day).round
    end

    def submit!
      update!(state: "submitted", submitted_at: Time.current)
    end

    def qualify!(user, notes: nil)
      update!(state: "qualified", qualified_by: user, qualified_at: Time.current, qualification_notes: notes)
    end

    def decide!(decision, notes: nil)
      raise ArgumentError, "decision" unless %w[go no_go].include?(decision)

      update!(state: decision, decided_at: Time.current, decision_notes: notes)
    end
  end
end
