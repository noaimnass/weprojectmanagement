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
  module Imports
    # Re-imports a register from the CSV produced by the export: rows with an existing reference
    # update the item, the others create one. Nothing is written before the preview is confirmed.
    class RegisterCsv
      Preview = Struct.new(:creations, :updates, :errors, :rows, keyword_init: true)

      COLUMNS = %w[reference kind title description status priority owner due_date closed_on probability impact details].freeze

      def initialize(project:, kind:, user:)
        @project = project
        @kind = kind
        @user = user
      end

      def preview(content)
        rows = parse(content)
        existing = @project.pilotage_register_items.of_kind(@kind).index_by(&:reference)
        creations = []
        updates = []
        errors = []
        rows.each_with_index do |row, index|
          item = existing[row["reference"]] || @project.pilotage_register_items.build(kind: @kind, created_by: @user)
          item.assign_attributes(attributes_for(row))
          if item.valid?
            (item.new_record? ? creations : updates) << row
          else
            errors << "#{index + 2}: #{item.errors.full_messages.join(', ')}"
          end
        end
        Preview.new(creations:, updates:, errors:, rows:)
      end

      def import!(content)
        rows = parse(content)
        existing = @project.pilotage_register_items.of_kind(@kind).index_by(&:reference)
        ActiveRecord::Base.transaction do
          rows.each do |row|
            item = existing[row["reference"]] || @project.pilotage_register_items.build(kind: @kind, created_by: @user)
            item.update!(attributes_for(row))
          end
        end
        rows.size
      end

      private

      def parse(content)
        text = content.to_s.delete_prefix(Pilotage::Exports::Csv::BOM)
        separator = text.lines.first.to_s.count(";") >= text.lines.first.to_s.count(",") ? ";" : ","
        CSV.parse(text, headers: true, col_sep: separator).map { |r| r.to_h.transform_keys { |k| k.to_s.strip.downcase } }
      end

      def attributes_for(row)
        {
          reference: row["reference"].presence,
          title: row["title"],
          description: row["description"],
          status: row["status"].presence || "open",
          priority: row["priority"].presence&.to_i || 2,
          owner: find_user(row["owner"]),
          due_date: parse_date(row["due_date"]),
          probability: row["probability"].presence&.to_i,
          impact: row["impact"].presence&.to_i,
          details: parse_details(row["details"])
        }.compact
      end

      def find_user(name)
        return nil if name.blank?

        User.where("LOWER(CONCAT(firstname, ' ', lastname)) = ? OR LOWER(login) = ? OR LOWER(mail) = ?",
                   name.downcase, name.downcase, name.downcase).first
      end

      def parse_date(value)
        return nil if value.blank?

        Date.parse(value)
      rescue ArgumentError
        nil
      end

      def parse_details(value)
        return {} if value.blank?

        JSON.parse(value)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
