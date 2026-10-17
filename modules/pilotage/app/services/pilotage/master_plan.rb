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
  # Geometry of the master plan: one lane per project, phases between lifecycle milestones,
  # on a common time scale (SVG rendered by the MasterPlanComponent).
  class MasterPlan
    Lane = Struct.new(:row, :segments, :start_on, :end_on, :baseline_end_on, :variance_days, keyword_init: true)
    Segment = Struct.new(:key, :label, :from, :to, :done, keyword_init: true)

    attr_reader :lanes, :from, :to

    def initialize(rows)
      @rows = rows
    end

    def call
      reviews = Pilotage::MilestoneReview.where(project_id: @rows.map { |r| r.project.id }).ordered.group_by(&:project_id)
      @lanes = @rows.filter_map { |row| lane_for(row, reviews[row.project.id] || []) }
      @from = (@lanes.map(&:start_on).min || Date.current).beginning_of_month
      @to = (@lanes.map { |l| [l.end_on, l.baseline_end_on].compact.max }.max || (Date.current >> 12)).end_of_month
      self
    end

    def months
      list = []
      cursor = from
      while cursor <= to
        list << cursor
        cursor >>= 1
      end
      list
    end

    def total_days
      [(to - from).to_i, 1].max
    end

    private

    def lane_for(row, project_reviews)
      profile = row.profile
      dated = project_reviews.select { |r| r.effective_date.present? }
      start_on = profile&.start_on || dated.first&.effective_date || row.project.created_at.to_date
      end_on = profile&.end_on || dated.last&.effective_date
      return nil if end_on.blank? || end_on < start_on

      segments = []
      if dated.size >= 2
        dated.each_cons(2) do |a, b|
          segments << Segment.new(key: a.key, label: a.label, from: a.effective_date, to: b.effective_date, done: a.passed?)
        end
      else
        phase = profile&.phase || "P0"
        segments << Segment.new(key: phase, label: Pilotage::Lifecycle.label(profile&.category, phase),
                                from: start_on, to: end_on, done: false)
      end

      Lane.new(row:, segments:, start_on:, end_on:, baseline_end_on: profile&.baseline_end_on,
               variance_days: profile&.schedule_variance_days)
    end
  end
end
