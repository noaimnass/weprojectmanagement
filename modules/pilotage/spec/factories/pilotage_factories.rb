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
FactoryBot.define do
  factory :pilotage_entity, class: "Pilotage::Entity" do
    sequence(:name) { |n| "Entité #{n}" }
    kind { "department" }
  end

  factory :pilotage_project_profile, class: "Pilotage::ProjectProfile" do
    project factory: :project
    project_class { "C" }
    phase { "P1" }
    start_on { Date.current - 30 }
    end_on { Date.current + 180 }
  end

  factory :pilotage_register_item, class: "Pilotage::RegisterItem" do
    project factory: :project
    kind { "risk" }
    sequence(:title) { |n| "Élément #{n}" }
    status { "open" }
    priority { 2 }
  end

  factory :pilotage_milestone_review, class: "Pilotage::MilestoneReview" do
    project factory: :project
    key { "P1" }
    label { "Cadrage validé" }
    planned_on { Date.current + 10 }
  end

  factory :pilotage_status_report, class: "Pilotage::StatusReport" do
    project factory: :project
    period_start { Date.current - 14 }
    period_end { Date.current }
    health { "green" }
    progress { 40 }
  end
end
