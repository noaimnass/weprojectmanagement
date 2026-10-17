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
  class SessionsController < BaseController
    before_action :authorize_global
    before_action :find_instance
    before_action :find_session, only: %i[show edit update destroy]

    menu_item :pilotage_governance

    def show
      @decisions = @session.decisions.includes(:project, :owner).ordered
    end

    def new
      @session = @instance.sessions.build(held_on: Date.current, title: @instance.name)
    end

    def create
      @session = @instance.sessions.build(session_params)
      if @session.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to pilotage_instance_session_path(@instance, @session)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @session.update(session_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to pilotage_instance_session_path(@instance, @session)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @session.destroy
      redirect_to pilotage_instance_path(@instance)
    end

    private

    def find_instance
      @instance = Pilotage::Instance.find(params[:instance_id])
    end

    def find_session
      @session = @instance.sessions.find(params[:id])
    end

    def session_params
      params.require(:pilotage_session).permit(:title, :held_on, :project_id, :meeting_id, :agenda, :minutes, :state)
    end
  end
end
