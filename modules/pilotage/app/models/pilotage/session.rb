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
  class Session < ApplicationRecord
    STATES = %w[planned held cancelled].freeze

    belongs_to :instance, class_name: "Pilotage::Instance", inverse_of: :sessions
    belongs_to :project, optional: true, inverse_of: :pilotage_sessions
    belongs_to :meeting, optional: true

    validates :title, presence: true, length: { maximum: 255 }
    validates :held_on, presence: true
    validates :state, inclusion: { in: STATES }

    scope :in_month, ->(date) { where(held_on: date.beginning_of_month..date.end_of_month) }
    scope :upcoming, -> { where("held_on >= ?", Date.current).order(:held_on) }

    def decisions
      Pilotage::RegisterItem.of_kind("decision").where("details->>'session_id' = ?", id.to_s)
    end
  end
end
