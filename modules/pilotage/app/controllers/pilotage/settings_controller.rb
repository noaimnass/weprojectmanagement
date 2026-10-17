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
  class SettingsController < ::Admin::SettingsController
    menu_item :pilotage_settings

    private

    def settings_params
      raw = params.require(:settings).permit!.to_h
      raw["pilotage_categories"] = split_lines(raw["pilotage_categories"]) if raw.key?("pilotage_categories")
      raw["pilotage_strategic_axes"] = split_lines(raw["pilotage_strategic_axes"]) if raw.key?("pilotage_strategic_axes")
      if raw.key?("pilotage_lifecycle_labels")
        raw["pilotage_lifecycle_labels"] = parse_labels(raw["pilotage_lifecycle_labels"])
      end
      raw.slice(*PermittedParams::AllowedSettings.all.map(&:to_s))
    end

    def split_lines(value)
      return value if value.is_a?(Array)

      value.to_s.split(/[\n,]/).map { |v| v.strip.parameterize(separator: "_") }.compact_blank
    end

    def parse_labels(value)
      return value if value.is_a?(Hash)

      YAML.safe_load(value.to_s).to_h
    rescue Psych::SyntaxError
      {}
    end
  end
end
