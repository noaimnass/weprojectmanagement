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
  module ProjectExtension
    extend ActiveSupport::Concern

    included do
      has_one :pilotage_profile, class_name: "Pilotage::ProjectProfile", dependent: :destroy
      has_many :pilotage_register_items, class_name: "Pilotage::RegisterItem", dependent: :destroy
      has_many :pilotage_milestone_reviews, -> { order(:position, :key) },
               class_name: "Pilotage::MilestoneReview", dependent: :destroy
      has_many :pilotage_status_reports, -> { order(period_end: :desc) },
               class_name: "Pilotage::StatusReport", dependent: :destroy
      has_many :pilotage_sessions, class_name: "Pilotage::Session", dependent: :nullify
      has_many :pilotage_project_requests, class_name: "Pilotage::ProjectRequest", dependent: :nullify
    end

    def pilotage_profile!
      pilotage_profile || build_pilotage_profile
    end

    def pilotage_class
      pilotage_profile&.project_class || "C"
    end
  end
end
