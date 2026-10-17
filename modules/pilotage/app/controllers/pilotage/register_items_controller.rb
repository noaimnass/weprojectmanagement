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
  class RegisterItemsController < BaseController
    before_action :load_and_authorize_in_optional_project, only: :index
    before_action :find_project_by_project_id, except: :index
    before_action :authorize, except: :index
    before_action :set_kind
    before_action :find_item, only: %i[show edit update destroy close]

    menu_item :pilotage_project_registers
    current_menu_item :index do |controller|
      controller.params[:project_id].present? ? :pilotage_project_registers : :pilotage_registers
    end

    def index
      scope = if @project
                @project.pilotage_register_items
              else
                Pilotage::RegisterItem.where(project_id: visible_project_ids)
              end
      scope = scope.of_kind(@kind).includes(:project, :owner)
      scope = scope.open_items if params[:status] == "open"
      scope = scope.closed_items if params[:status] == "closed"
      scope = scope.where(owner_id: params[:owner_id]) if params[:owner_id].present?
      scope = scope.where("LOWER(title) LIKE ?", "%#{params[:q].to_s.downcase}%") if params[:q].present?
      @items = scope.ordered.page(page_param).per_page(per_page_param)
    end

    def show; end

    def new
      @item = @project.pilotage_register_items.build(kind: @kind, owner: current_user)
    end

    def create
      @item = @project.pilotage_register_items.build(item_params.merge(kind: @kind, created_by: current_user))
      if @item.save
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_pilotage_register_items_path(@project, kind: @kind)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @item.update(item_params)
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_pilotage_register_items_path(@project, kind: @item.kind)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def close
      @item.update(status: "closed")
      flash[:notice] = I18n.t(:notice_successful_update)
      redirect_to project_pilotage_register_items_path(@project, kind: @item.kind)
    end

    def destroy
      @item.destroy
      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_to project_pilotage_register_items_path(@project, kind: @item.kind)
    end

    def export
      items = @project.pilotage_register_items.of_kind(@kind).includes(:owner).ordered
      send_data Pilotage::Exports::Csv.register_items(items),
                type: "text/csv; charset=utf-8; header=present",
                filename: "#{@project.identifier}-#{@kind}-#{Date.current.iso8601}.csv"
    end

    def import
      return unless request.post?

      file = params[:file]
      if file.blank?
        flash.now[:error] = I18n.t("pilotage.registers.import.no_file")
        return render :import, status: :unprocessable_entity
      end

      @content = file.read.force_encoding("UTF-8")
      @preview = Pilotage::Imports::RegisterCsv.new(project: @project, kind: @kind, user: current_user).preview(@content)
      @encoded = Base64.strict_encode64(@content)
      render :import_preview
    end

    def import_confirm
      content = Base64.strict_decode64(params[:content].to_s).force_encoding("UTF-8")
      count = Pilotage::Imports::RegisterCsv.new(project: @project, kind: @kind, user: current_user).import!(content)
      flash[:notice] = I18n.t("pilotage.registers.import.done", count:)
      redirect_to project_pilotage_register_items_path(@project, kind: @kind)
    rescue ActiveRecord::RecordInvalid, ArgumentError => e
      flash[:error] = I18n.t("pilotage.registers.import.failed", error: e.message)
      redirect_to import_project_pilotage_register_items_path(@project, kind: @kind)
    end

    private

    def set_kind
      @kind = Pilotage::RegisterItem::KINDS.include?(params[:kind].to_s) ? params[:kind].to_s : "risk"
    end

    def find_item
      @item = @project.pilotage_register_items.find(params[:id])
      @kind = @item.kind
    end

    def item_params
      permitted = params.require(:pilotage_register_item)
                        .permit(:title, :description, :status, :owner_id, :due_date, :priority, :probability, :impact,
                                details: Pilotage::RegisterItem::DETAIL_FIELDS.fetch(@kind, []))
      permitted[:details] = permitted[:details].to_h.compact_blank if permitted[:details]
      permitted
    end
  end
end
