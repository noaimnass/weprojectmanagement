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

class CreatePilotageTables < ActiveRecord::Migration[8.1]
  def change
    create_table :pilotage_entities do |t|
      t.string :name, null: false
      t.string :code
      t.string :kind, null: false, default: "department"
      t.references :parent, foreign_key: { to_table: :pilotage_entities }
      t.references :head, foreign_key: { to_table: :users }
      t.integer :headcount
      t.decimal :budget, precision: 15, scale: 2
      t.string :cost_center
      t.string :external_ref
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :pilotage_entities, :code, unique: true, where: "code IS NOT NULL"

    create_table :pilotage_project_profiles do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.string :category
      t.string :project_class, null: false, default: "C"
      t.string :portfolio
      t.string :program
      t.string :strategic_axis
      t.references :pilot_entity, foreign_key: { to_table: :pilotage_entities }
      t.references :sponsor, foreign_key: { to_table: :users }
      t.references :manager, foreign_key: { to_table: :users }
      t.references :correspondent, foreign_key: { to_table: :users }
      t.decimal :budget_total, precision: 15, scale: 2
      t.decimal :budget_committed, precision: 15, scale: 2
      t.decimal :budget_spent, precision: 15, scale: 2
      t.string :phase, null: false, default: "P0"
      t.string :declared_health, null: false, default: "green"
      t.text :health_comment
      t.date :start_on
      t.date :end_on
      t.date :baseline_end_on
      t.integer :entities_count, null: false, default: 1
      t.string :financial_ref
      t.text :objectives
      t.text :scope_summary
      t.timestamps
    end
    add_index :pilotage_project_profiles, :project_class
    add_index :pilotage_project_profiles, :category

    create_table :pilotage_register_items do |t|
      t.references :project, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :reference, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "open"
      t.references :owner, foreign_key: { to_table: :users }
      t.references :created_by, foreign_key: { to_table: :users }
      t.date :due_date
      t.date :closed_on
      t.integer :priority, null: false, default: 2
      t.integer :probability
      t.integer :impact
      t.jsonb :details, null: false, default: {}
      t.timestamps
    end
    add_index :pilotage_register_items, %i[project_id kind]
    add_index :pilotage_register_items, %i[project_id reference], unique: true
    add_index :pilotage_register_items, :status

    create_table :pilotage_milestone_reviews do |t|
      t.references :project, null: false, foreign_key: true
      t.string :key, null: false
      t.string :label, null: false
      t.date :planned_on
      t.date :forecast_on
      t.date :actual_on
      t.string :decision, null: false, default: "pending"
      t.date :decided_on
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.references :work_package, foreign_key: true
      t.text :notes
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :pilotage_milestone_reviews, %i[project_id key], unique: true

    create_table :pilotage_status_reports do |t|
      t.references :project, null: false, foreign_key: true
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :health, null: false, default: "green"
      t.string :schedule_signal, null: false, default: "green"
      t.string :budget_signal, null: false, default: "green"
      t.string :scope_signal, null: false, default: "green"
      t.string :risk_signal, null: false, default: "green"
      t.integer :progress, null: false, default: 0
      t.text :summary
      t.text :highlights
      t.text :next_steps
      t.text :decisions_needed
      t.string :state, null: false, default: "draft"
      t.references :submitted_by, foreign_key: { to_table: :users }
      t.datetime :submitted_at
      t.references :validated_by, foreign_key: { to_table: :users }
      t.datetime :validated_at
      t.text :validation_comment
      t.timestamps
    end
    add_index :pilotage_status_reports, %i[project_id period_end]
    add_index :pilotage_status_reports, :state

    create_table :pilotage_project_requests do |t|
      t.string :title, null: false
      t.text :description
      t.references :requester, foreign_key: { to_table: :users }
      t.references :entity, foreign_key: { to_table: :pilotage_entities }
      t.string :category
      t.string :strategic_axis
      t.decimal :estimated_budget, precision: 15, scale: 2
      t.integer :estimated_duration_months
      t.integer :entities_count, null: false, default: 1
      t.text :expected_benefits
      t.string :state, null: false, default: "draft"
      t.datetime :submitted_at
      t.references :qualified_by, foreign_key: { to_table: :users }
      t.datetime :qualified_at
      t.text :qualification_notes
      t.datetime :decided_at
      t.text :decision_notes
      t.references :project, foreign_key: true
      t.timestamps
    end
    add_index :pilotage_project_requests, :state

    create_table :pilotage_instances do |t|
      t.string :name, null: false
      t.string :level, null: false, default: "project"
      t.string :periodicity
      t.references :chair, foreign_key: { to_table: :users }
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :pilotage_sessions do |t|
      t.references :instance, null: false, foreign_key: { to_table: :pilotage_instances }
      t.references :project, foreign_key: true
      t.references :meeting, foreign_key: true
      t.string :title, null: false
      t.date :held_on, null: false
      t.text :agenda
      t.text :minutes
      t.string :state, null: false, default: "planned"
      t.timestamps
    end
    add_index :pilotage_sessions, :held_on
  end
end
