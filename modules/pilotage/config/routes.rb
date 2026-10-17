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

Rails.application.routes.draw do
  scope "pilotage", module: "pilotage", as: "pilotage" do
    get "/", to: "cockpit#show", as: "cockpit"
    get "indicators", to: "cockpit#indicators", as: "indicators"

    get "portfolio", to: "portfolio#index", as: "portfolio"
    get "master_plan", to: "portfolio#master_plan", as: "master_plan"
    get "workload", to: "portfolio#workload", as: "workload"
    get "compliance", to: "portfolio#compliance", as: "compliance"
    post "compliance/remind", to: "portfolio#remind", as: "compliance_remind"

    get "reports/control_tower", to: "reports#control_tower", as: "control_tower"
    get "reports/executive", to: "reports#executive", as: "executive_report"

    get "registers(/:kind)", to: "register_items#index", as: "registers"

    resources :project_requests do
      member do
        patch :qualify
        patch :decide
        post :convert
      end
    end

    resources :entities

    get "governance", to: "governance#index", as: "governance"
    get "governance/agenda", to: "governance#agenda", as: "governance_agenda"
    get "governance/decisions", to: "governance#decisions", as: "governance_decisions"
    resources :instances do
      resources :sessions, except: %i[index]
    end

    get "reference", to: "reference#show", as: "reference"
  end

  scope "admin", module: "pilotage", as: "admin_pilotage" do
    get "pilotage", to: "settings#show", as: "settings"
    patch "pilotage", to: "settings#update"
  end

  scope "projects/:project_id/pilotage", module: "pilotage", as: "project_pilotage" do
    get "/", to: "project_cockpit#show", as: "cockpit"
    get "flash", to: "project_cockpit#flash_report", as: "flash"
    get "profile/edit", to: "profiles#edit", as: "profile_edit"
    patch "profile", to: "profiles#update", as: "profile"

    resources :register_items, path: "registers" do
      member do
        patch :close
      end
      collection do
        get :export
        get :import
        post :import
        post :import_confirm
      end
    end

    resources :milestone_reviews, only: %i[index edit update destroy] do
      collection do
        post :create_defaults
      end
    end

    resources :status_reports do
      member do
        patch :submit
        patch :validate
        patch :reject
      end
    end
  end
end
