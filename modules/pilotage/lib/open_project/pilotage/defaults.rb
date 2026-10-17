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
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Pilotage
    module Defaults
      CATEGORIES = [
        "transformation",
        "information_systems",
        "infrastructure",
        "organisation_processes",
        "products_services",
        "compliance_risk",
        "steering_support"
      ].freeze

      AXES = [
        "performance",
        "customer_experience",
        "digital",
        "people_culture",
        "sustainability",
        "growth"
      ].freeze

      LIFECYCLE_KEYS = %w[P0 P1 P2 P3 P4 P5 P6 P7 P8].freeze

      CLASSES = %w[A B C].freeze

      HEALTH = %w[green amber red].freeze

      REGISTER_KINDS = %w[risk issue decision action change_request deliverable benefit stakeholder impact].freeze
    end
  end
end
