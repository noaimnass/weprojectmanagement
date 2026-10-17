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
require "csv"

module Pilotage
  module Exports
    # CSV exports (UTF-8 with BOM, semicolon separated) for registers and the portfolio.
    module Csv
      module_function

      BOM = "\xEF\xBB\xBF"

      def generate(headers, rows)
        BOM + CSV.generate(col_sep: ";") do |csv|
          csv << headers
          rows.each { |row| csv << row }
        end
      end

      def register_items(items)
        headers = %w[reference kind title description status priority owner due_date closed_on probability impact details]
        generate(headers, items.map do |item|
          [item.reference, item.kind, item.title, item.description, item.status, item.priority,
           item.owner&.name, item.due_date, item.closed_on, item.probability, item.impact, item.details.to_json]
        end)
      end

      def portfolio(rows)
        headers = %w[project identifier class category phase health schedule budget risk reporting progress
                     budget_total budget_spent manager sponsor entity end_on baseline_end_on variance_days]
        generate(headers, rows.map do |row|
          p = row.profile
          s = row.signals
          [row.project.name, row.project.identifier, row.project_class, p&.category, row.phase, s.computed_health,
           s.schedule, s.budget, s.risk, s.reporting, s.progress, p&.budget_total, p&.budget_spent,
           p&.manager&.name, p&.sponsor&.name, row.entity&.name, p&.end_on, p&.baseline_end_on, p&.schedule_variance_days]
        end)
      end
    end
  end
end
