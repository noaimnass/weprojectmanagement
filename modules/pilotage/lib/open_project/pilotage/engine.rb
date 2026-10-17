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
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/plugins"
require "open_project/pilotage/defaults"

module OpenProject::Pilotage
  class Engine < ::Rails::Engine
    engine_name :openproject_pilotage

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-pilotage",
             author_url: "https://weworld.tech",
             bundled: true,
             settings: {} do
      project_module nil do
        permission :view_pilotage_portfolio,
                   {
                     "pilotage/cockpit": %i[show indicators],
                     "pilotage/portfolio": %i[index master_plan workload compliance],
                     "pilotage/reports": %i[control_tower executive],
                     "pilotage/register_items": %i[index],
                     "pilotage/project_requests": %i[index show new create],
                     "pilotage/entities": %i[index show],
                     "pilotage/governance": %i[index agenda decisions],
                     "pilotage/instances": %i[index show],
                     "pilotage/sessions": %i[show],
                     "pilotage/reference": %i[show]
                   },
                   permissible_on: :global,
                   require: :loggedin

        permission :manage_pilotage_portfolio,
                   {
                     "pilotage/project_requests": %i[edit update destroy qualify decide convert],
                     "pilotage/entities": %i[new create edit update destroy],
                     "pilotage/instances": %i[new create edit update destroy],
                     "pilotage/sessions": %i[new create edit update destroy],
                     "pilotage/status_reports": %i[validate reject],
                     "pilotage/portfolio": %i[remind]
                   },
                   permissible_on: :global,
                   require: :loggedin,
                   dependencies: :view_pilotage_portfolio
      end

      project_module :pilotage, dependencies: :work_package_tracking do
        enabled_by_default!

        permission :view_pilotage,
                   {
                     "pilotage/project_cockpit": %i[show flash_report],
                     "pilotage/register_items": %i[index show export],
                     "pilotage/milestone_reviews": %i[index],
                     "pilotage/status_reports": %i[index show]
                   },
                   permissible_on: :project,
                   dependencies: :view_work_packages,
                   contract_actions: { pilotage: %i[read] }

        permission :manage_pilotage,
                   {
                     "pilotage/profiles": %i[edit update],
                     "pilotage/register_items": %i[new create edit update destroy close import import_confirm],
                     "pilotage/milestone_reviews": %i[create_defaults edit update destroy],
                     "pilotage/status_reports": %i[new create edit update submit destroy]
                   },
                   permissible_on: :project,
                   dependencies: :view_pilotage,
                   contract_actions: { pilotage: %i[create update destroy] }
      end

      should_render = Proc.new do
        User.current.logged? && User.current.allowed_globally?(:view_pilotage_portfolio)
      end

      menu :top_menu,
           :pilotage,
           { controller: "/pilotage/cockpit", action: "show" },
           context: :modules,
           caption: :"pilotage.label_pilotage",
           icon: "pulse",
           first: true,
           if: should_render

      menu :global_menu,
           :pilotage,
           { controller: "/pilotage/cockpit", action: "show" },
           caption: :"pilotage.label_pilotage",
           icon: "pulse",
           first: true,
           if: should_render

      {
        pilotage_cockpit: ["/pilotage/cockpit", "show", :"pilotage.label_cockpit", "pulse"],
        pilotage_portfolio: ["/pilotage/portfolio", "index", :"pilotage.label_portfolio", "project"],
        pilotage_master_plan: ["/pilotage/portfolio", "master_plan", :"pilotage.label_master_plan", "graph"],
        pilotage_workload: ["/pilotage/portfolio", "workload", :"pilotage.label_workload", "people"],
        pilotage_compliance: ["/pilotage/portfolio", "compliance", :"pilotage.label_compliance", "checklist"],
        pilotage_registers: ["/pilotage/register_items", "index", :"pilotage.label_registers", "list-unordered"],
        pilotage_project_requests: ["/pilotage/project_requests", "index", :"pilotage.label_project_requests", "inbox"],
        pilotage_entities: ["/pilotage/entities", "index", :"pilotage.label_organisation", "organization"],
        pilotage_governance: ["/pilotage/governance", "index", :"pilotage.label_governance", "law"],
        pilotage_reports: ["/pilotage/reports", "control_tower", :"pilotage.label_reports", "report"],
        pilotage_reference: ["/pilotage/reference", "show", :"pilotage.label_reference", "book"]
      }.each do |item, (controller, action, caption, icon)|
        menu :global_menu,
             item,
             { controller:, action: },
             parent: :pilotage,
             caption:,
             icon:,
             if: should_render
      end

      menu :project_menu,
           :pilotage,
           { controller: "/pilotage/project_cockpit", action: "show" },
           caption: :"pilotage.label_pilotage",
           icon: "pulse",
           after: :work_packages,
           if: ->(project) { project.module_enabled?(:pilotage) }

      {
        pilotage_project_cockpit: ["/pilotage/project_cockpit", "show", :"pilotage.label_cockpit"],
        pilotage_project_registers: ["/pilotage/register_items", "index", :"pilotage.label_registers"],
        pilotage_project_milestones: ["/pilotage/milestone_reviews", "index", :"pilotage.label_milestone_reviews"],
        pilotage_project_reports: ["/pilotage/status_reports", "index", :"pilotage.label_status_reports"]
      }.each do |item, (controller, action, caption)|
        menu :project_menu,
             item,
             { controller:, action: },
             parent: :pilotage,
             caption:,
             if: ->(project) { project.module_enabled?(:pilotage) }
      end

      menu :admin_menu,
           :pilotage_settings,
           { controller: "/pilotage/settings", action: "show" },
           if: Proc.new { User.current.admin? },
           caption: :"pilotage.label_pilotage",
           icon: "pulse"
    end

    initializer "pilotage.settings" do
      ::Settings::Definition.add "pilotage_currency", default: "MAD", format: :string
      ::Settings::Definition.add "pilotage_budget_unit", default: 1_000_000, format: :integer
      ::Settings::Definition.add "pilotage_eligibility_budget", default: 0.5, format: :float
      ::Settings::Definition.add "pilotage_eligibility_months", default: 3, format: :integer
      ::Settings::Definition.add "pilotage_eligibility_entities", default: 2, format: :integer
      ::Settings::Definition.add "pilotage_class_a_budget", default: 10.0, format: :float
      ::Settings::Definition.add "pilotage_class_a_entities", default: 4, format: :integer
      ::Settings::Definition.add "pilotage_class_a_entities_budget", default: 3.0, format: :float
      ::Settings::Definition.add "pilotage_class_b_budget", default: 1.5, format: :float
      ::Settings::Definition.add "pilotage_class_b_entities", default: 3, format: :integer
      ::Settings::Definition.add "pilotage_class_b_entities_budget", default: 1.0, format: :float
      ::Settings::Definition.add "pilotage_cadence_a_days", default: 7, format: :integer
      ::Settings::Definition.add "pilotage_cadence_b_days", default: 15, format: :integer
      ::Settings::Definition.add "pilotage_cadence_c_days", default: 31, format: :integer
      ::Settings::Definition.add "pilotage_horizon_days", default: 45, format: :integer
      ::Settings::Definition.add "pilotage_monthly_capacity_hours", default: 140, format: :integer
      ::Settings::Definition.add "pilotage_categories",
                                 default: OpenProject::Pilotage::Defaults::CATEGORIES,
                                 format: :array
      ::Settings::Definition.add "pilotage_strategic_axes",
                                 default: OpenProject::Pilotage::Defaults::AXES,
                                 format: :array
      ::Settings::Definition.add "pilotage_lifecycle_labels",
                                 default: {},
                                 format: :hash
    end

    include_module "Pilotage::ProjectExtension", into: "Project"
  end
end
