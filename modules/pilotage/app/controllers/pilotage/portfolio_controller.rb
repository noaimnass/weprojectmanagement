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
  class PortfolioController < BaseController
    before_action :authorize_global

    menu_item :pilotage_portfolio
    menu_item :pilotage_master_plan, only: :master_plan
    menu_item :pilotage_workload, only: :workload
    menu_item :pilotage_compliance, only: %i[compliance remind]

    def index
      @summary = portfolio_summary
      respond_to do |format|
        format.html
        format.csv do
          send_data Pilotage::Exports::CSV.portfolio(@summary.rows),
                    type: "text/csv; charset=utf-8; header=present",
                    filename: "portefeuille-#{Date.current.iso8601}.csv"
        end
      end
    end

    def master_plan
      @summary = portfolio_summary
      @plan = Pilotage::MasterPlan.new(@summary.rows).call
    end

    def workload
      @summary = portfolio_summary
      @workload = Pilotage::Workload.new(project_ids: @summary.project_ids, user: current_user).call
    end

    def compliance
      @summary = portfolio_summary
      @rows = @summary.rows.sort_by { |r| [-OpenProject::Pilotage::Defaults::HEALTH.index(r.signals.reporting), r.project.name] }
    end

    def remind
      summary = portfolio_summary(filters: {}, grouping: "none")
      late = summary.rows.reject { |r| r.signals.reporting == "green" }
      created = 0
      late.each do |row|
        owner = row.profile&.correspondent || row.profile&.manager
        next if row.project.pilotage_register_items.of_kind("action").open_items
                   .where("details->>'origin' = ?", "reporting_reminder").exists?

        row.project.pilotage_register_items.create!(
          kind: "action", title: I18n.t("pilotage.compliance.reminder_title"),
          description: I18n.t("pilotage.compliance.reminder_description", cadence: row.profile&.reporting_cadence_days || 31),
          owner:, created_by: current_user, due_date: Date.current + 3, priority: 1,
          details: { "origin" => "reporting_reminder" }
        )
        created += 1
      end
      flash[:notice] = I18n.t("pilotage.compliance.reminders_created", count: created)
      redirect_to pilotage_compliance_path
    end
  end
end
