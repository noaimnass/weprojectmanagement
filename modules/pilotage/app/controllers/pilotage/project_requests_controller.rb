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
  class ProjectRequestsController < BaseController
    before_action :authorize_global
    before_action :find_request, only: %i[show edit update destroy qualify decide convert]

    menu_item :pilotage_project_requests

    def index
      scope = Pilotage::ProjectRequest.includes(:requester, :entity, :project).recent_first
      scope = scope.where(state: params[:state]) if params[:state].present?
      @requests = scope.page(page_param).per_page(per_page_param)
      @counts = Pilotage::ProjectRequest.group(:state).count
    end

    def show; end

    def new
      @request_item = Pilotage::ProjectRequest.new(requester: current_user, entities_count: 1)
    end

    def create
      @request_item = Pilotage::ProjectRequest.new(request_params.merge(requester: current_user))
      @request_item.state = "submitted"
      @request_item.submitted_at = Time.current
      if @request_item.save
        flash[:notice] = I18n.t("pilotage.project_requests.submitted")
        redirect_to pilotage_project_request_path(@request_item)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @request_item.update(request_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to pilotage_project_request_path(@request_item)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @request_item.destroy
      redirect_to pilotage_project_requests_path
    end

    def qualify
      @request_item.qualify!(current_user, notes: params[:notes])
      flash[:notice] = I18n.t("pilotage.project_requests.qualified")
      redirect_to pilotage_project_request_path(@request_item)
    end

    def decide
      @request_item.decide!(params[:decision], notes: params[:notes])
      flash[:notice] = I18n.t("pilotage.project_requests.decided")
      redirect_to pilotage_project_request_path(@request_item)
    rescue ArgumentError
      flash[:error] = I18n.t("pilotage.project_requests.errors.decision")
      redirect_to pilotage_project_request_path(@request_item)
    end

    def convert
      result = Pilotage::ConvertRequestService.new(@request_item, user: current_user).call
      if result.success?
        flash[:notice] = I18n.t("pilotage.project_requests.converted")
        redirect_to project_pilotage_cockpit_path(result.result)
      else
        flash[:error] = result.message
        redirect_to pilotage_project_request_path(@request_item)
      end
    end

    private

    def find_request
      @request_item = Pilotage::ProjectRequest.find(params[:id])
    end

    def request_params
      params.require(:pilotage_project_request)
            .permit(:title, :description, :entity_id, :category, :strategic_axis, :estimated_budget,
                    :estimated_duration_months, :entities_count, :expected_benefits)
    end
  end
end
