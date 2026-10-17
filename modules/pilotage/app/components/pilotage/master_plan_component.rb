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
  # Server-rendered SVG master plan: one lane per project, phases on a shared time scale.
  class MasterPlanComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    options :plan
    options label_width: 220, lane_height: 34, header_height: 28, print: false

    LANE_PADDING = 6

    def width
      1100
    end

    def chart_width
      width - label_width - 20
    end

    def height
      header_height + plan.lanes.size * lane_height + 10
    end

    def x_for(date)
      label_width + ((date - plan.from).to_f / plan.total_days * chart_width).round(1)
    end

    def today_x
      x_for(Date.current.clamp(plan.from, plan.to))
    end

    def lane_y(index)
      header_height + index * lane_height
    end

    def segment_class(lane, segment)
      classes = ["segment"]
      classes << "segment--done" if segment.done
      classes << "segment--#{lane.row.signals.schedule}" if %w[amber red].include?(lane.row.signals.schedule) && !segment.done
      classes.join(" ")
    end

    def variance_text(lane)
      return nil if lane.variance_days.nil? || lane.variance_days.zero?

      Kernel.format("%+d j", lane.variance_days)
    end

    def truncate_name(name, max = 32)
      name.length > max ? "#{name[0, max - 1]}…" : name
    end

    def month_label(date)
      I18n.l(date, format: "%b %y")
    end
  end
end
