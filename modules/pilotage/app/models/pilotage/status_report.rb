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
  class StatusReport < ApplicationRecord
    HEALTH = OpenProject::Pilotage::Defaults::HEALTH
    STATES = %w[draft submitted validated rejected].freeze
    SIGNALS = %i[schedule_signal budget_signal scope_signal risk_signal].freeze

    belongs_to :project, inverse_of: :pilotage_status_reports
    belongs_to :submitted_by, class_name: "User", optional: true
    belongs_to :validated_by, class_name: "User", optional: true

    validates :period_start, :period_end, presence: true
    validates :health, inclusion: { in: HEALTH }
    SIGNALS.each { |signal| validates signal, inclusion: { in: HEALTH } }
    validates :state, inclusion: { in: STATES }
    validates :progress, numericality: { in: 0..100 }
    validate :period_consistency

    scope :validated, -> { where(state: "validated") }
    scope :awaiting_validation, -> { where(state: "submitted") }
    scope :recent_first, -> { order(period_end: :desc, id: :desc) }

    def self.visible(user = User.current)
      where(project_id: Project.allowed_to(user, :view_pilotage).select(:id))
    end

    def editable?
      %w[draft rejected].include?(state)
    end

    def submit!(user)
      update!(state: "submitted", submitted_by: user, submitted_at: Time.current)
    end

    def validate_by!(user, comment: nil)
      raise ArgumentError, "self_validation" if submitted_by_id == user.id && !user.admin?

      update!(state: "validated", validated_by: user, validated_at: Time.current, validation_comment: comment)
    end

    def reject!(user, comment: nil)
      update!(state: "rejected", validated_by: user, validated_at: Time.current, validation_comment: comment)
    end

    def computed_health
      [health, *SIGNALS.map { |s| public_send(s) }].max_by { |h| HEALTH.index(h) }
    end

    def validation_delay_days
      return nil if submitted_at.blank? || validated_at.blank?

      ((validated_at - submitted_at) / 1.day).round
    end

    private

    def period_consistency
      return if period_start.blank? || period_end.blank?

      errors.add(:period_end, :greater_than_start_date) if period_end < period_start
    end
  end
end
