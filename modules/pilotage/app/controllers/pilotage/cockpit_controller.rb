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
  class CockpitController < BaseController
    before_action :authorize_global

    menu_item :pilotage_cockpit

    def show
      @summary = portfolio_summary(filters: {}, grouping: "none")
      ids = @summary.project_ids
      @my_space = Pilotage::MySpace.new(current_user, project_ids: ids)
      @upcoming_milestones = Pilotage::MilestoneReview.where(project_id: ids).upcoming.includes(:project).order(:planned_on).limit(12)
      @late_milestones = Pilotage::MilestoneReview.where(project_id: ids).late.includes(:project).order(:planned_on).limit(12)
      @awaiting_validation = Pilotage::StatusReport.where(project_id: ids).awaiting_validation.includes(:project, :submitted_by).limit(10)
      @decisions_needed = Pilotage::StatusReport.where(project_id: ids).validated.where.not(decisions_needed: [nil, ""])
                                                .select("DISTINCT ON (project_id) *").order(:project_id, period_end: :desc)
                                                .includes(:project).to_a.sort_by(&:period_end).reverse.first(10)
      @change_requests = Pilotage::RegisterItem.where(project_id: ids).of_kind("change_request").open_items.includes(:project).ordered.limit(10)
      @pending_requests = Pilotage::ProjectRequest.pending.includes(:requester, :entity).recent_first.limit(10)
      @indicators = Pilotage::DeviceIndicators.new(@summary).call
    end

    def indicators
      @summary = portfolio_summary(filters: {}, grouping: "none")
      @indicators = Pilotage::DeviceIndicators.new(@summary).call
    end
  end
end
