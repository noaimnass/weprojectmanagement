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
  # "Mon espace": what the current user has to do across the portfolio.
  class MySpace
    attr_reader :user

    def initialize(user, project_ids:)
      @user = user
      @project_ids = project_ids
    end

    def tasks
      WorkPackage.visible(user).with_status_open.where(assigned_to_id: user.id)
                 .includes(:project, :type, :status).order(Arel.sql("due_date NULLS LAST")).limit(15)
    end

    def actions
      Pilotage::RegisterItem.where(project_id: @project_ids, owner_id: user.id).of_kind("action").open_items
                            .includes(:project).ordered.limit(15)
    end

    def validations
      return Pilotage::StatusReport.none unless user.allowed_globally?(:manage_pilotage_portfolio)

      Pilotage::StatusReport.where(project_id: @project_ids).awaiting_validation.includes(:project, :submitted_by)
                            .order(:submitted_at).limit(15)
    end

    def milestone_reviews
      Pilotage::MilestoneReview.where(project_id: @project_ids).where(decision: "pending")
                               .upcoming.includes(:project).order(:planned_on).limit(15)
    end

    def sessions
      Pilotage::Session.upcoming.includes(:instance, :project).limit(10)
    end
  end
end
