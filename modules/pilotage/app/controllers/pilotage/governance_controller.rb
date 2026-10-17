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
  class GovernanceController < BaseController
    before_action :authorize_global

    menu_item :pilotage_governance

    def index
      @instances = Pilotage::Instance.ordered.includes(:chair)
      @upcoming = Pilotage::Session.upcoming.includes(:instance, :project).limit(20)
    end

    def agenda
      @month = parse_month
      ids = visible_project_ids
      @sessions = Pilotage::Session.in_month(@month).includes(:instance, :project).order(:held_on)
      @milestones = Pilotage::MilestoneReview.where(project_id: ids).where(planned_on: @month.beginning_of_month..@month.end_of_month)
                                             .includes(:project).order(:planned_on)
      @reports_due = portfolio_summary(filters: {}, grouping: "none").rows.select { |r| r.signals.reporting != "green" }
      @days = (@month.beginning_of_month..@month.end_of_month).to_a
    end

    def decisions
      scope = Pilotage::RegisterItem.of_kind("decision").where(project_id: visible_project_ids).includes(:project, :owner)
      scope = scope.where("details->>'instance' = ?", params[:instance]) if params[:instance].present?
      scope = scope.where("details->>'session_id' = ?", params[:session_id]) if params[:session_id].present?
      @decisions = scope.order(created_at: :desc).page(page_param).per_page(per_page_param)
      @instances = Pilotage::Instance.ordered
    end

    private

    def parse_month
      Date.parse("#{params[:month]}-01")
    rescue ArgumentError, TypeError
      Date.current.beginning_of_month
    end
  end
end
