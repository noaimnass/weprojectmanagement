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
  class MilestoneReview < ApplicationRecord
    KEYS = OpenProject::Pilotage::Defaults::LIFECYCLE_KEYS
    DECISIONS = %w[pending go conditional no_go].freeze

    belongs_to :project, inverse_of: :pilotage_milestone_reviews
    belongs_to :reviewed_by, class_name: "User", optional: true
    belongs_to :work_package, optional: true

    validates :key, presence: true, uniqueness: { scope: :project_id }
    validates :label, presence: true, length: { maximum: 255 }
    validates :decision, inclusion: { in: DECISIONS }

    scope :ordered, -> { order(:position, :key) }
    scope :upcoming, ->(days = Setting.pilotage_horizon_days) {
      where(actual_on: nil).where(planned_on: Date.current..(Date.current + days.to_i))
    }
    scope :late, -> { where(actual_on: nil).where("planned_on < ?", Date.current) }

    def self.visible(user = User.current)
      where(project_id: Project.allowed_to(user, :view_pilotage).select(:id))
    end

    def passed?
      actual_on.present? && %w[go conditional].include?(decision)
    end

    def late?
      actual_on.nil? && planned_on.present? && planned_on < Date.current
    end

    def days_late
      return 0 unless late?

      (Date.current - planned_on).to_i
    end

    def held_on_time?
      actual_on.present? && planned_on.present? && actual_on <= planned_on
    end

    def effective_date
      actual_on || forecast_on || planned_on
    end

    def sync_from_work_package!
      return if work_package.blank?

      update(planned_on: work_package.due_date || work_package.start_date,
             actual_on: work_package.status&.is_closed? ? (work_package.due_date || Date.current) : actual_on)
    end
  end
end
