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
namespace :pilotage do
  desc "Create the default governance bodies (project committee, portfolio review, control tower, strategic committee)"
  task seed_governance: :environment do
    [
      ["Comité projet", "project", "biweekly"],
      ["Revue de portefeuille", "portfolio", "monthly"],
      ["Tour de contrôle", "control_tower", "monthly"],
      ["Comité stratégique", "strategic", "quarterly"]
    ].each_with_index do |(name, level, periodicity), index|
      Pilotage::Instance.find_or_create_by!(name:) do |instance|
        instance.level = level
        instance.periodicity = periodicity
        instance.position = index
      end
    end
    puts "Governance bodies ready."
  end

  desc "Enable the Pilotage module on every active project and create its steering profile and milestones"
  task enable_all: :environment do
    Project.active.find_each do |project|
      project.enabled_module_names |= %w[pilotage]
      profile = project.pilotage_profile || project.create_pilotage_profile!(
        start_on: project.created_at.to_date, end_on: project.created_at.to_date >> 12
      )
      dates = Pilotage::Lifecycle.default_dates(profile.start_on, profile.end_on)
      Pilotage::Lifecycle.milestones(profile.category).each_with_index do |(key, label), index|
        project.pilotage_milestone_reviews.find_or_create_by!(key:) do |review|
          review.label = label
          review.planned_on = dates[key]
          review.position = index
        end
      end
    end
    puts "Pilotage enabled on #{Project.active.count} projects."
  end

  desc "Fill the steering layer with demonstration data on projects that have the module enabled (demo instances only)"
  task demo: %i[environment seed_governance] do
    users = User.human.active.to_a
    admin = User.admin.first || users.first
    abort "No user available" if admin.nil?

    root = Pilotage::Entity.find_or_create_by!(name: "Direction générale", kind: "organisation", code: "DG")
    divisions = ["Finance et achats", "Opérations", "Systèmes d'information", "Ressources humaines"].map.with_index do |name, i|
      Pilotage::Entity.find_or_create_by!(name:) { |e| e.kind = "division"; e.parent = root; e.position = i; e.headcount = 40 + i * 25; e.budget = 5_000_000 + i * 2_000_000 }
    end

    categories = Pilotage::Lifecycle.categories
    axes = Pilotage::Lifecycle.axes
    projects = Project.active.joins(:enabled_modules).where(enabled_modules: { name: "pilotage" }).distinct.to_a
    projects.each_with_index do |project, i|
      start_on = Date.current - (60 + i * 20)
      end_on = start_on + (240 + i * 30)
      profile = project.pilotage_profile || project.build_pilotage_profile
      profile.assign_attributes(
        category: categories[i % categories.size], strategic_axis: axes[i % axes.size],
        pilot_entity: divisions[i % divisions.size], sponsor: users.sample, manager: users.sample, correspondent: users.sample,
        budget_total: [800_000, 2_500_000, 12_000_000][i % 3] * (1 + i % 2), budget_spent: nil, entities_count: 1 + i % 4,
        start_on:, end_on:, baseline_end_on: end_on - [0, 15, -10][i % 3], phase: Pilotage::Lifecycle::KEYS[1 + i % 5],
        financial_ref: i.even? ? "WBS-#{1000 + i}" : nil, objectives: "Objectifs de démonstration du projet #{project.name}."
      )
      profile.budget_spent = (profile.budget_total * [0.35, 0.7, 1.05][i % 3]).round
      profile.save!
      dates = Pilotage::Lifecycle.default_dates(start_on, end_on)
      Pilotage::Lifecycle.milestones(profile.category).each_with_index do |(key, label), index|
        review = project.pilotage_milestone_reviews.find_or_initialize_by(key:)
        review.label = label
        review.planned_on = dates[key]
        review.position = index
        if index < profile.phase_index
          review.decision = "go"
          review.actual_on = dates[key] + (index.odd? ? 3 : -2)
          review.decided_on = review.actual_on
        end
        review.save!
      end
      next if project.pilotage_register_items.any?

      [["risk", "Disponibilité des ressources clés", 4, 4], ["risk", "Dérive du périmètre fonctionnel", 3, 3],
       ["issue", "Environnement de recette instable", nil, nil], ["action", "Préparer le comité de pilotage", nil, nil],
       ["decision", "Validation du planning directeur", nil, nil], ["deliverable", "Dossier de cadrage", nil, nil],
       ["benefit", "Réduction des délais de traitement", nil, nil], ["stakeholder", "Direction métier", nil, nil],
       ["impact", "Nouveau processus de validation", 3, 4], ["change_request", "Extension du périmètre aux filiales", nil, nil]].each do |kind, title, p, im|
        details = case kind
                  when "benefit" then { "indicator" => "Délai moyen (jours)", "unit" => "j", "target_value" => "10", "measured_value" => (i.even? ? "12" : nil) }.compact
                  when "stakeholder" then { "entity_id" => divisions[i % divisions.size].id, "role" => "Sponsor métier", "influence" => "high", "support" => "medium" }
                  when "impact" then { "entity_id" => divisions[(i + 1) % divisions.size].id, "population" => "Gestionnaires", "level" => "high" }
                  when "deliverable" then { "phase" => "P1", "version" => "1.0" }
                  when "decision" then { "instance" => "Comité projet" }
                  else {}
                  end
        project.pilotage_register_items.create!(kind:, title:, probability: p, impact: im, owner: users.sample, created_by: admin,
                                                due_date: Date.current + rand(-10..40), priority: 1 + rand(3), details:)
      end
      [60, 30, 10].each_with_index do |days_ago, r|
        report = project.pilotage_status_reports.create!(
          period_start: Date.current - days_ago - 14, period_end: Date.current - days_ago,
          health: %w[green amber green][(i + r) % 3], schedule_signal: %w[green amber red][(i + r) % 3], budget_signal: "green",
          scope_signal: "green", risk_signal: %w[green green amber][(i + r) % 3], progress: [20, 45, 70][r] + i % 10,
          summary: "Point d'avancement de démonstration (#{days_ago} jours).", next_steps: "Préparer la prochaine revue de jalon.",
          decisions_needed: r == 2 && i.even? ? "Arbitrage sur le renfort de l'équipe de recette." : nil
        )
        report.update!(state: "validated", submitted_by: users.sample, submitted_at: report.period_end.to_time + 1.day,
                       validated_by: admin, validated_at: report.period_end.to_time + 2.days) unless r == 2 && i % 4 == 3
      end
    end

    tower = Pilotage::Instance.find_by(level: "control_tower")
    tower.sessions.find_or_create_by!(title: "Tour de contrôle", held_on: Date.current.end_of_month) if tower
    [["Nouveau portail des demandes internes", 1_200_000, 8, 3], ["Rénovation du siège", 25_000_000, 18, 2]].each do |title, budget, months, entities|
      Pilotage::ProjectRequest.find_or_create_by!(title:) do |r|
        r.requester = users.sample
        r.entity = divisions.sample
        r.category = categories.first
        r.estimated_budget = budget
        r.estimated_duration_months = months
        r.entities_count = entities
        r.state = "submitted"
        r.submitted_at = Time.current - 5.days
      end
    end
    puts "Demo data created on #{projects.size} projects."
  end
end
