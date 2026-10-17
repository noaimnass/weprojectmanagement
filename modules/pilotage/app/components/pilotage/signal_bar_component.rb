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
  # Horizontal stacked bar of counts per health level (green / amber / red).
  class SignalBarComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    options :counts, :title

    def total
      counts.values.sum
    end

    def width(level)
      return 0 if total.zero?

      (counts.fetch(level, 0) * 100.0 / total).round(1)
    end

    def levels
      OpenProject::Pilotage::Defaults::HEALTH
    end
  end
end
