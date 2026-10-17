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
  class ProfilesController < BaseController
    before_action :find_project_by_project_id
    before_action :authorize

    menu_item :pilotage_project_cockpit

    def edit
      @profile = project_profile
    end

    def update
      @profile = project_profile
      if @profile.update(profile_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_pilotage_cockpit_path(@project)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:pilotage_project_profile)
            .permit(:category, :project_class, :portfolio, :program, :strategic_axis, :pilot_entity_id,
                    :sponsor_id, :manager_id, :correspondent_id, :budget_total, :budget_committed, :budget_spent,
                    :phase, :declared_health, :health_comment, :start_on, :end_on, :baseline_end_on,
                    :entities_count, :financial_ref, :objectives, :scope_summary)
    end
  end
end
