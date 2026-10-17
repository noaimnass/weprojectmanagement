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
  class ReportsController < BaseController
    before_action :authorize_global

    menu_item :pilotage_reports

    def control_tower
      @summary = portfolio_summary
      ids = @summary.project_ids
      @indicators = Pilotage::DeviceIndicators.new(@summary).call
      @upcoming_milestones = Pilotage::MilestoneReview.where(project_id: ids).upcoming.includes(:project).order(:planned_on)
      @late_milestones = Pilotage::MilestoneReview.where(project_id: ids).late.includes(:project).order(:planned_on)
      @pending_requests = Pilotage::ProjectRequest.pending.includes(:requester, :entity).recent_first
      @change_requests = Pilotage::RegisterItem.where(project_id: ids).of_kind("change_request").open_items
                                               .includes(:project).ordered
      @decisions_needed = latest_validated_reports(ids).select { |r| r.decisions_needed.present? }
      render_print "pilotage/reports/control_tower"
    end

    def executive
      @summary = portfolio_summary
      ids = @summary.project_ids
      @indicators = Pilotage::DeviceIndicators.new(@summary).call
      @plan = Pilotage::MasterPlan.new(@summary.rows).call
      @reports = latest_validated_reports(ids).index_by(&:project_id)
      @top_risks = Pilotage::RegisterItem.where(project_id: ids).of_kind("risk").open_items.includes(:project, :owner)
                                         .where.not(probability: nil).where.not(impact: nil)
                                         .order(Arel.sql("probability * impact DESC")).limit(10)
      render_print "pilotage/reports/executive"
    end

    private

    def latest_validated_reports(ids)
      Pilotage::StatusReport.where(project_id: ids).validated
                            .select("DISTINCT ON (project_id) *").order(:project_id, period_end: :desc)
                            .includes(:project).to_a
    end
  end
end
