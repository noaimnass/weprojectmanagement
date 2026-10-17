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
  # Monthly load per person over the next twelve months, from the estimated hours of open work packages
  # spread evenly between their start and due dates.
  class Workload
    Cell = Struct.new(:hours, :count, keyword_init: true)

    attr_reader :months

    def initialize(project_ids:, user: User.current, months: 12, from: Date.current.beginning_of_month)
      @project_ids = project_ids
      @user = user
      @months = (0...months).map { |i| from >> i }
    end

    def call
      @matrix = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = Cell.new(hours: 0.0, count: 0) } }
      work_packages.find_each { |wp| spread(wp) }
      self
    end

    def people
      @matrix.keys.sort_by { |p| p.name.downcase }
    end

    def hours(person, month)
      @matrix.dig(person, month)&.hours || 0.0
    end

    def total(person)
      months.sum { |m| hours(person, m) }
    end

    def overloaded?(person, month)
      hours(person, month) > capacity
    end

    def capacity
      Setting.pilotage_monthly_capacity_hours.to_f
    end

    def overload_count
      people.sum { |p| months.count { |m| overloaded?(p, m) } }
    end

    private

    def work_packages
      WorkPackage.visible(@user).with_status_open
                 .where(project_id: @project_ids)
                 .where.not(assigned_to_id: nil).where.not(estimated_hours: nil)
                 .includes(:assigned_to)
    end

    def spread(work_package)
      person = work_package.assigned_to
      return if person.nil?

      from = work_package.start_date || work_package.due_date || Date.current
      to = work_package.due_date || from
      from, to = to, from if to < from
      span_months = ((to.year - from.year) * 12 + to.month - from.month).abs + 1
      share = work_package.estimated_hours.to_f / span_months
      months.each do |month|
        next unless month >= from.beginning_of_month && month <= to.beginning_of_month

        cell = @matrix[person][month]
        cell.hours += share
        cell.count += 1
      end
    end
  end
end
