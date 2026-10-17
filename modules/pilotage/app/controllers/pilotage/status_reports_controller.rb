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
  class StatusReportsController < BaseController
    before_action :find_project_by_project_id, except: %i[validate reject]
    before_action :find_project_for_validation, only: %i[validate reject]
    before_action :authorize, except: %i[validate reject]
    before_action :authorize_global, only: %i[validate reject]
    before_action :find_report, only: %i[show edit update destroy submit validate reject]

    menu_item :pilotage_project_reports

    def index
      @profile = project_profile
      @reports = @project.pilotage_status_reports.recent_first.includes(:submitted_by, :validated_by)
                         .page(page_param).per_page(per_page_param)
    end

    def show; end

    def new
      @signals = project_signals
      last = @project.pilotage_status_reports.recent_first.first
      cadence = project_profile.reporting_cadence_days
      @report = @project.pilotage_status_reports.build(
        period_start: last ? last.period_end + 1 : Date.current - cadence,
        period_end: Date.current,
        health: @signals.computed_health,
        schedule_signal: @signals.schedule,
        budget_signal: @signals.budget,
        risk_signal: @signals.risk,
        progress: @signals.progress || 0
      )
    end

    def create
      @report = @project.pilotage_status_reports.build(report_params)
      if @report.save
        @report.submit!(current_user) if params[:submit].present?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_pilotage_status_report_path(@project, @report)
      else
        @signals = project_signals
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      return redirect_to(project_pilotage_status_report_path(@project, @report)) unless @report.editable?

      @signals = project_signals
    end

    def update
      return redirect_to(project_pilotage_status_report_path(@project, @report)) unless @report.editable?

      if @report.update(report_params)
        @report.submit!(current_user) if params[:submit].present?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_pilotage_status_report_path(@project, @report)
      else
        @signals = project_signals
        render :edit, status: :unprocessable_entity
      end
    end

    def submit
      @report.submit!(current_user) if @report.editable?
      redirect_to project_pilotage_status_report_path(@project, @report)
    end

    def validate
      @report.validate_by!(current_user, comment: params[:comment])
      project_profile.update(declared_health: @report.health)
      flash[:notice] = I18n.t("pilotage.reports.validated")
      redirect_to project_pilotage_status_report_path(@project, @report)
    rescue ArgumentError
      flash[:error] = I18n.t("pilotage.reports.self_validation")
      redirect_to project_pilotage_status_report_path(@project, @report)
    end

    def reject
      @report.reject!(current_user, comment: params[:comment])
      flash[:notice] = I18n.t("pilotage.reports.rejected")
      redirect_to project_pilotage_status_report_path(@project, @report)
    end

    def destroy
      @report.destroy if @report.editable?
      redirect_to project_pilotage_status_reports_path(@project)
    end

    private

    def find_report
      @report = @project.pilotage_status_reports.find(params[:id])
    end

    # Validators act with a global permission and may not be members of a private project.
    def find_project_for_validation
      @project = Project.active.find(params[:project_id])
    end

    def report_params
      params.require(:pilotage_status_report)
            .permit(:period_start, :period_end, :health, :schedule_signal, :budget_signal, :scope_signal, :risk_signal,
                    :progress, :summary, :highlights, :next_steps, :decisions_needed)
    end
  end
end
