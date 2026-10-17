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
  class Entity < ApplicationRecord
    KINDS = %w[organisation division department pole school service unit].freeze

    belongs_to :parent, class_name: "Pilotage::Entity", optional: true, inverse_of: :children
    belongs_to :head, class_name: "User", optional: true
    has_many :children, -> { order(:position, :name) },
             class_name: "Pilotage::Entity", foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
    has_many :project_profiles, class_name: "Pilotage::ProjectProfile", foreign_key: :pilot_entity_id,
                                dependent: :nullify, inverse_of: :pilot_entity
    has_many :project_requests, class_name: "Pilotage::ProjectRequest", foreign_key: :entity_id,
                                dependent: :nullify, inverse_of: :entity

    validates :name, presence: true, length: { maximum: 255 }
    validates :kind, inclusion: { in: KINDS }
    validates :code, uniqueness: true, allow_blank: true
    validate :parent_is_not_self_or_descendant

    scope :active, -> { where(active: true) }
    scope :roots, -> { where(parent_id: nil) }
    scope :ordered, -> { order(:position, :name) }

    def self.tree
      nodes = active.ordered.to_a
      by_parent = nodes.group_by(&:parent_id)
      build = lambda do |parent_id, depth|
        (by_parent[parent_id] || []).flat_map do |node|
          [[node, depth]] + build.call(node.id, depth + 1)
        end
      end
      build.call(nil, 0)
    end

    def self_and_descendant_ids
      ids = [id]
      queue = [id]
      until queue.empty?
        current = Pilotage::Entity.where(parent_id: queue).pluck(:id)
        ids.concat(current)
        queue = current
      end
      ids.uniq
    end

    def ancestors
      list = []
      node = parent
      while node && list.size < 50
        list << node
        node = node.parent
      end
      list.reverse
    end

    def full_name
      (ancestors + [self]).map(&:name).join(" › ")
    end

    def piloted_projects
      Project.joins(:pilotage_profile).where(pilotage_project_profiles: { pilot_entity_id: self_and_descendant_ids })
    end

    def impacting_projects
      Project.joins(:pilotage_register_items)
             .where(pilotage_register_items: { kind: "impact" })
             .where("pilotage_register_items.details->>'entity_id' IN (?)", self_and_descendant_ids.map(&:to_s))
             .distinct
    end

    def label
      code.present? ? "#{code} · #{name}" : name
    end

    private

    def parent_is_not_self_or_descendant
      return if parent_id.blank? || new_record?

      errors.add(:parent_id, :invalid) if self_and_descendant_ids.include?(parent_id)
    end
  end
end
