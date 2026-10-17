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
  class RegisterItem < ApplicationRecord
    KINDS = OpenProject::Pilotage::Defaults::REGISTER_KINDS
    STATUSES = %w[open in_progress closed cancelled].freeze
    PRIORITIES = { 1 => "high", 2 => "medium", 3 => "low" }.freeze

    PREFIXES = {
      "risk" => "R", "issue" => "I", "decision" => "D", "action" => "A", "change_request" => "C",
      "deliverable" => "L", "benefit" => "B", "stakeholder" => "S", "impact" => "M"
    }.freeze

    # Attributes stored in the details JSON column, per kind.
    DETAIL_FIELDS = {
      "risk" => %w[category mitigation contingency trigger],
      "issue" => %w[severity resolution],
      "decision" => %w[instance session_id rationale],
      "action" => %w[origin],
      "change_request" => %w[impact_schedule impact_budget impact_scope decision_instance],
      "deliverable" => %w[phase version acceptance],
      "benefit" => %w[indicator unit target_value measured_value measured_on],
      "stakeholder" => %w[entity_id role influence support],
      "impact" => %w[entity_id population nature level]
    }.freeze

    belongs_to :project, inverse_of: :pilotage_register_items
    belongs_to :owner, class_name: "User", optional: true
    belongs_to :created_by, class_name: "User", optional: true

    validates :kind, inclusion: { in: KINDS }
    validates :title, presence: true, length: { maximum: 255 }
    validates :status, inclusion: { in: STATUSES }
    validates :priority, inclusion: { in: PRIORITIES.keys }
    validates :probability, :impact, inclusion: { in: 1..5 }, allow_nil: true
    validates :reference, presence: true, uniqueness: { scope: :project_id }

    before_validation :assign_reference, on: :create
    before_save :sync_closed_on

    scope :of_kind, ->(kind) { where(kind:) }
    scope :open_items, -> { where(status: %w[open in_progress]) }
    scope :closed_items, -> { where(status: %w[closed cancelled]) }
    scope :overdue, -> { open_items.where("due_date < ?", Date.current) }
    scope :ordered, -> {
      order(Arel.sql("CASE WHEN status IN ('open','in_progress') THEN 0 ELSE 1 END"), :priority, :due_date, :id)
    }

    def self.visible(user = User.current)
      where(project_id: Project.allowed_to(user, :view_pilotage).select(:id))
    end

    def open?
      %w[open in_progress].include?(status)
    end

    def overdue?
      open? && due_date.present? && due_date < Date.current
    end

    def criticality
      return nil if probability.blank? || impact.blank?

      probability * impact
    end

    def criticality_level
      case criticality
      when nil then nil
      when 16.. then "red"
      when 10..15 then "amber"
      else "green"
      end
    end

    def detail(key)
      details&.dig(key.to_s)
    end

    def detail_fields
      DETAIL_FIELDS.fetch(kind, [])
    end

    def priority_key
      PRIORITIES[priority]
    end

    def entity
      return nil unless %w[stakeholder impact].include?(kind)

      @entity ||= Pilotage::Entity.find_by(id: detail(:entity_id))
    end

    private

    def assign_reference
      return if reference.present?

      prefix = PREFIXES.fetch(kind, "X")
      last = self.class.where(project_id:, kind:).where("reference LIKE ?", "#{prefix}-%")
                 .pluck(:reference).map { |r| r.split("-").last.to_i }.max || 0
      self.reference = format("%s-%03d", prefix, last + 1)
    end

    def sync_closed_on
      if %w[closed cancelled].include?(status)
        self.closed_on ||= Date.current
      else
        self.closed_on = nil
      end
    end
  end
end
