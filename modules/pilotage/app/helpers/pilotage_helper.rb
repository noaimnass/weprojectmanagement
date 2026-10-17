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
module PilotageHelper
  HEALTH_SCHEMES = { "green" => :success, "amber" => :attention, "red" => :danger }.freeze

  def pilotage_health_label(level, text: nil, size: :medium)
    level = level.to_s.presence || "green"
    render(Primer::Beta::Label.new(scheme: HEALTH_SCHEMES.fetch(level, :secondary), size:,
                                   classes: "pilotage-signal pilotage-signal--#{level}")) do
      text || t("pilotage.health.#{level}")
    end
  end

  def pilotage_signal_dot(level, title: nil)
    level = level.to_s.presence || "green"
    content_tag(:span, "", class: "pilotage-dot pilotage-dot--#{level}", title: title || t("pilotage.health.#{level}"),
                           "aria-label": title || t("pilotage.health.#{level}"))
  end

  def pilotage_class_label(klass)
    render(Primer::Beta::Label.new(scheme: klass == "A" ? :accent : :secondary)) do
      t("pilotage.classes.#{klass}", default: klass)
    end
  end

  def pilotage_phase_label(key)
    render(Primer::Beta::Label.new(scheme: :primary)) { key }
  end

  def pilotage_state_label(state, scope:)
    scheme = case state.to_s
             when "validated", "go", "held", "converted", "closed" then :success
             when "submitted", "qualified", "planned", "in_progress", "conditional" then :attention
             when "rejected", "no_go", "cancelled" then :danger
             else :secondary
             end
    render(Primer::Beta::Label.new(scheme:)) { t("pilotage.#{scope}.states.#{state}", default: state.to_s.humanize) }
  end

  def pilotage_money(amount, unit: false)
    return "–" if amount.blank?

    currency = Setting.pilotage_currency
    if unit
      units = Pilotage::Classification.to_units(amount)
      "#{number_with_precision(units, precision: 2, delimiter: ' ', separator: ',')} M#{currency}"
    else
      "#{number_with_delimiter(amount.to_d.round, delimiter: ' ')} #{currency}"
    end
  end

  def pilotage_percent(value)
    value.nil? ? "–" : "#{value} %"
  end

  def pilotage_date(date)
    date.present? ? format_date(date) : "–"
  end

  def pilotage_user(user)
    user.present? ? user.name : "–"
  end

  def pilotage_kind_label(kind)
    t("pilotage.registers.kinds.#{kind}", default: kind.to_s.humanize)
  end

  def pilotage_register_path_for(project, kind)
    if project
      project_pilotage_register_items_path(project, kind:)
    else
      pilotage_registers_path(kind:)
    end
  end

  def pilotage_user_options(project = nil)
    users = if project
              project.users.active
            else
              User.human.active
            end
    users.order(:lastname, :firstname).map { |u| [u.name, u.id] }
  end

  def pilotage_entity_options
    Pilotage::Entity.tree.map { |entity, depth| ["#{'— ' * depth}#{entity.name}", entity.id] }
  end

  def pilotage_category_options
    Pilotage::Lifecycle.categories.map { |c| [Pilotage::Lifecycle.category_label(c), c] }
  end

  def pilotage_axis_options
    Pilotage::Lifecycle.axes.map { |a| [Pilotage::Lifecycle.axis_label(a), a] }
  end

  def pilotage_progress_bar(value, scheme: nil)
    value = value.to_i.clamp(0, 100)
    scheme ||= value >= 80 ? :success : :default
    render(Primer::Beta::ProgressBar.new(size: :default)) do |bar|
      bar.with_item(percentage: value, bg: scheme == :success ? :success_emphasis : :accent_emphasis)
    end
  end

  def pilotage_horizon_days
    Setting.pilotage_horizon_days.to_i
  end
end
