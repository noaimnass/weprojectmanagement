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
  class MilestoneReviewsController < BaseController
    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_review, only: %i[edit update destroy]

    menu_item :pilotage_project_milestones

    def index
      @profile = project_profile
      @reviews = @project.pilotage_milestone_reviews.ordered.includes(:reviewed_by, :work_package)
      @milestone_work_packages = @project.work_packages.visible.joins(:type).where(types: { is_milestone: true })
                                         .order(:due_date).limit(50)
    end

    def create_defaults
      profile = project_profile
      dates = Pilotage::Lifecycle.default_dates(profile.start_on, profile.end_on)
      Pilotage::Lifecycle.milestones(profile.category).each_with_index do |(key, label), index|
        next if @project.pilotage_milestone_reviews.exists?(key:)

        @project.pilotage_milestone_reviews.create!(key:, label:, planned_on: dates[key], position: index)
      end
      flash[:notice] = I18n.t("pilotage.milestones.defaults_created")
      redirect_to project_pilotage_milestone_reviews_path(@project)
    end

    def edit; end

    def update
      attributes = review_params
      if attributes[:decision].present? && attributes[:decision] != "pending"
        attributes[:decided_on] ||= Date.current
        attributes[:reviewed_by_id] = current_user.id
        attributes[:actual_on] ||= Date.current if %w[go conditional].include?(attributes[:decision])
      end
      if @review.update(attributes)
        sync_phase
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_pilotage_milestone_reviews_path(@project)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @review.destroy
      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_to project_pilotage_milestone_reviews_path(@project)
    end

    private

    def find_review
      @review = @project.pilotage_milestone_reviews.find(params[:id])
    end

    def review_params
      params.require(:pilotage_milestone_review)
            .permit(:label, :planned_on, :forecast_on, :actual_on, :decision, :decided_on, :work_package_id, :notes)
    end

    # The last milestone passed with a "go" moves the project to the next phase, without re-entry.
    def sync_phase
      passed = @project.pilotage_milestone_reviews.ordered.select(&:passed?).last
      return if passed.nil?

      keys = Pilotage::Lifecycle::KEYS
      next_key = keys[[keys.index(passed.key).to_i + 1, keys.size - 1].min]
      profile = project_profile
      profile.update(phase: next_key) if keys.index(next_key).to_i > profile.phase_index
    end
  end
end
