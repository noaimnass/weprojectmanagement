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
  # Turns a project request decided "go" into a project (phase P0) with its steering profile.
  class ConvertRequestService
    def initialize(request, user:)
      @request = request
      @user = user
    end

    def call
      return ServiceResult.failure(message: I18n.t("pilotage.project_requests.errors.not_go")) unless @request.state == "go"
      unless @user.allowed_globally?(:add_project)
        return ServiceResult.failure(message: I18n.t("pilotage.project_requests.errors.add_project"))
      end

      identifier = Project.suggest_identifier(@request.title).presence || "projet"
      result = Projects::CreateService.new(user: @user).call(
        name: @request.title,
        identifier: unique_identifier(identifier),
        description: @request.description,
        workspace_type: "project",
        enabled_module_names: Setting.default_projects_modules | %w[pilotage]
      )
      return result if result.failure?

      project = result.result
      Pilotage::ProjectProfile.create!(
        project:,
        category: @request.category,
        strategic_axis: @request.strategic_axis,
        pilot_entity: @request.entity,
        budget_total: @request.estimated_budget,
        entities_count: @request.entities_count,
        phase: "P0",
        manager: @request.requester,
        objectives: @request.expected_benefits,
        start_on: Date.current,
        end_on: @request.estimated_duration_months.to_i.positive? ? Date.current >> @request.estimated_duration_months : nil
      )
      @request.update!(state: "converted", project:)
      ServiceResult.success(result: project)
    end

    private

    def unique_identifier(base)
      candidate = base
      index = 1
      while Project.exists?(identifier: candidate)
        index += 1
        candidate = "#{base}-#{index}"
      end
      candidate
    end
  end
end
