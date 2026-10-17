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
  class ProjectCockpitController < BaseController
    before_action :find_project_by_project_id
    before_action :authorize

    menu_item :pilotage_project_cockpit

    def show
      @profile = project_profile
      @signals = project_signals
      @milestones = @project.pilotage_milestone_reviews.ordered.to_a
      @latest_report = @project.pilotage_status_reports.validated.recent_first.first
      @pending_report = @project.pilotage_status_reports.where(state: %w[draft submitted]).recent_first.first
      @registers = OpenProject::Pilotage::Defaults::REGISTER_KINDS.index_with do |kind|
        items = @project.pilotage_register_items.of_kind(kind)
        { total: items.count, open: items.open_items.count, overdue: items.overdue.count }
      end
      @top_risks = @project.pilotage_register_items.of_kind("risk").open_items.includes(:owner)
                           .order(Arel.sql("COALESCE(probability * impact, 0) DESC")).limit(5)
      @open_actions = @project.pilotage_register_items.of_kind("action").open_items.includes(:owner).ordered.limit(8)
      @recent_decisions = @project.pilotage_register_items.of_kind("decision").order(created_at: :desc).limit(5)
      @deliverables = @project.pilotage_register_items.of_kind("deliverable").ordered.limit(8)
      @open_work_packages = @project.work_packages.visible.with_status_open.count
      @overdue_work_packages = @project.work_packages.visible.with_status_open.where(due_date: ...Date.current).count
      @sessions = @project.pilotage_sessions.includes(:instance).order(held_on: :desc).limit(5)
    end

    def flash_report
      @profile = project_profile
      @signals = project_signals
      @milestones = @project.pilotage_milestone_reviews.ordered.to_a
      @latest_report = @project.pilotage_status_reports.validated.recent_first.first
      @top_risks = @project.pilotage_register_items.of_kind("risk").open_items.includes(:owner)
                           .order(Arel.sql("COALESCE(probability * impact, 0) DESC")).limit(5)
      @open_actions = @project.pilotage_register_items.of_kind("action").open_items.includes(:owner).ordered.limit(8)
      @recent_decisions = @project.pilotage_register_items.of_kind("decision").order(created_at: :desc).limit(5)
      @open_issues = @project.pilotage_register_items.of_kind("issue").open_items.includes(:owner).ordered.limit(5)
      render_print "pilotage/project_cockpit/flash"
    end
  end
end
