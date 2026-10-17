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
  # Common P0–P8 life cycle; milestone labels can be adapted per category
  # through the pilotage_lifecycle_labels setting ({ "category" => { "P1" => "label" } }).
  module Lifecycle
    module_function

    KEYS = OpenProject::Pilotage::Defaults::LIFECYCLE_KEYS

    def categories
      Array(Setting.pilotage_categories).presence || OpenProject::Pilotage::Defaults::CATEGORIES
    end

    def axes
      Array(Setting.pilotage_strategic_axes).presence || OpenProject::Pilotage::Defaults::AXES
    end

    def category_label(category)
      return "" if category.blank?

      I18n.t("pilotage.categories.#{category}", default: category.to_s.humanize)
    end

    def axis_label(axis)
      return "" if axis.blank?

      I18n.t("pilotage.axes.#{axis}", default: axis.to_s.humanize)
    end

    def label(category, key)
      custom = Setting.pilotage_lifecycle_labels.to_h.dig(category.to_s, key.to_s)
      custom.presence || I18n.t("pilotage.lifecycle.#{key}", default: key.to_s)
    end

    def milestones(category)
      KEYS.map { |key| [key, label(category, key)] }
    end

    # Default planned dates: spread the milestones between start and end.
    def default_dates(start_on, end_on)
      return KEYS.index_with { nil } if start_on.blank? || end_on.blank? || end_on < start_on

      span = (end_on - start_on).to_i
      KEYS.each_with_index.to_h do |key, index|
        [key, start_on + (span * index / (KEYS.size - 1).to_f).round]
      end
    end
  end
end
