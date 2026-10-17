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
  # Classification of projects (A/B/C), eligibility rules and reporting cadences.
  # Thresholds are expressed in budget units (Setting.pilotage_budget_unit, 1 MDH by default).
  module Classification
    module_function

    def unit
      Setting.pilotage_budget_unit.to_d.nonzero? || 1.to_d
    end

    def to_units(amount)
      return nil if amount.blank?

      amount.to_d / unit
    end

    def classify(budget_total:, entities_count:)
      units = to_units(budget_total) || 0.to_d
      entities = entities_count.to_i

      if units >= Setting.pilotage_class_a_budget.to_d ||
         (entities >= Setting.pilotage_class_a_entities.to_i && units >= Setting.pilotage_class_a_entities_budget.to_d)
        "A"
      elsif units >= Setting.pilotage_class_b_budget.to_d ||
            (entities >= Setting.pilotage_class_b_entities.to_i && units >= Setting.pilotage_class_b_entities_budget.to_d)
        "B"
      else
        "C"
      end
    end

    def eligibility(budget:, months:, entities:)
      {
        budget: (to_units(budget) || 0.to_d) >= Setting.pilotage_eligibility_budget.to_d,
        duration: months.to_i >= Setting.pilotage_eligibility_months.to_i,
        entities: entities.to_i >= Setting.pilotage_eligibility_entities.to_i
      }
    end

    def cadence_days(project_class)
      case project_class
      when "A" then Setting.pilotage_cadence_a_days.to_i
      when "B" then Setting.pilotage_cadence_b_days.to_i
      else Setting.pilotage_cadence_c_days.to_i
      end
    end
  end
end
