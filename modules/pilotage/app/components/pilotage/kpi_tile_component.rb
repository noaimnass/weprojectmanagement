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
  class KpiTileComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    options :label, :value, :hint, :href
    options scheme: :default, unit: nil

    def scheme_class
      "pilotage-kpi--#{scheme}"
    end

    def display_value
      value.nil? ? "–" : "#{value}#{unit}"
    end
  end
end
