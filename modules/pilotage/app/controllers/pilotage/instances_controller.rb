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
  class InstancesController < BaseController
    before_action :authorize_global
    before_action :find_instance, only: %i[show edit update destroy]

    menu_item :pilotage_governance

    def index
      redirect_to pilotage_governance_path
    end

    def show
      @sessions = @instance.sessions.includes(:project).page(page_param).per_page(per_page_param)
    end

    def new
      @instance = Pilotage::Instance.new
    end

    def create
      @instance = Pilotage::Instance.new(instance_params)
      if @instance.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to pilotage_instance_path(@instance)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @instance.update(instance_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to pilotage_instance_path(@instance)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @instance.destroy
      redirect_to pilotage_governance_path
    end

    private

    def find_instance
      @instance = Pilotage::Instance.find(params[:id])
    end

    def instance_params
      params.require(:pilotage_instance).permit(:name, :level, :periodicity, :chair_id, :description, :position)
    end
  end
end
