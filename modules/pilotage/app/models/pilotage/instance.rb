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
  class Instance < ApplicationRecord
    LEVELS = %w[project portfolio control_tower strategic].freeze
    PERIODICITIES = %w[weekly biweekly monthly quarterly on_demand].freeze

    belongs_to :chair, class_name: "User", optional: true
    has_many :sessions, -> { order(held_on: :desc) }, class_name: "Pilotage::Session",
                                                       foreign_key: :instance_id, dependent: :destroy, inverse_of: :instance

    validates :name, presence: true, length: { maximum: 255 }
    validates :level, inclusion: { in: LEVELS }
    validates :periodicity, inclusion: { in: PERIODICITIES }, allow_blank: true

    scope :ordered, -> {
      order(Arel.sql("array_position(ARRAY['strategic','control_tower','portfolio','project'], level)"), :position, :name)
    }

    def level_rank
      LEVELS.index(level)
    end
  end
end
