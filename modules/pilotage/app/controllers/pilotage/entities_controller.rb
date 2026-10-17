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
  class EntitiesController < BaseController
    before_action :authorize_global
    before_action :find_entity, only: %i[show edit update destroy]

    menu_item :pilotage_entities

    def index
      @tree = Pilotage::Entity.tree
      ids = Pilotage::Entity.pluck(:id)
      @projects_by_entity = Pilotage::ProjectProfile.where(pilot_entity_id: ids).group(:pilot_entity_id).count
      @summary = portfolio_summary(filters: {}, grouping: "entity")
    end

    def show
      @children = @entity.children.active
      @summary = Pilotage::PortfolioSummary.new(user: current_user, projects: @entity.piloted_projects).call
      @impacting = @entity.impacting_projects.where(id: visible_project_ids).includes(:pilotage_profile).to_a
      @benefits = Pilotage::RegisterItem.of_kind("benefit").where(project_id: @summary.project_ids)
                                        .includes(:project).ordered.limit(20)
      @stakeholders = Pilotage::RegisterItem.of_kind("stakeholder").where("details->>'entity_id' = ?", @entity.id.to_s)
                                            .where(project_id: visible_project_ids).includes(:project)
      @requests = @entity.project_requests.recent_first.limit(10)
      @workload = Pilotage::Workload.new(project_ids: @summary.project_ids, user: current_user, months: 6).call
    end

    def new
      @entity = Pilotage::Entity.new(parent_id: params[:parent_id])
    end

    def create
      @entity = Pilotage::Entity.new(entity_params)
      if @entity.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to pilotage_entity_path(@entity)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @entity.update(entity_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to pilotage_entity_path(@entity)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @entity.destroy
      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_to pilotage_entities_path
    end

    private

    def find_entity
      @entity = Pilotage::Entity.find(params[:id])
    end

    def entity_params
      params.require(:pilotage_entity)
            .permit(:name, :code, :kind, :parent_id, :head_id, :headcount, :budget, :cost_center, :external_ref,
                    :description, :active, :position)
    end
  end
end
