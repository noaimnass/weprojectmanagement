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
  class BaseController < ApplicationController
    helper :pilotage
    include PaginationHelper

    layout :pilotage_layout

    menu_item :pilotage

    private

    def pilotage_layout
      @project.present? ? "base" : "global"
    end

    def portfolio_summary(filters: params.permit(*Pilotage::PortfolioSummary::FILTERS).to_h, grouping: params[:group_by])
      Pilotage::PortfolioSummary.new(user: current_user, filters:, grouping:).call
    end

    def visible_project_ids
      @visible_project_ids ||= Project.allowed_to(current_user, :view_pilotage).active.pluck(:id)
    end

    def project_profile
      @project_profile ||= @project.pilotage_profile!
    end

    def project_signals
      @project_signals ||= Pilotage::Signals.new(@project, profile: project_profile).call
    end

    def render_print(template, locals = {})
      render template, layout: "pilotage/print", locals:
    end
  end
end
