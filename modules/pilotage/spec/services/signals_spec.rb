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
require_relative "../spec_helper"

RSpec.describe Pilotage::Signals do
  let(:project) { create(:project) }
  let!(:profile) { create(:pilotage_project_profile, project:, project_class: "B", budget_total: 1_000_000, budget_spent: 950_000) }

  it "is green on every signal for a fresh project with a validated report" do
    report = create(:pilotage_status_report, project:)
    report.update!(state: "validated", validated_at: Time.current)
    profile.update!(budget_spent: 0)

    result = described_class.new(project).call

    expect(result.schedule).to eq("green")
    expect(result.risk).to eq("green")
    expect(result.reporting).to eq("green")
    expect(result.computed_health).to eq("green")
  end

  it "turns the reporting signal red without any validated report and flags false greens" do
    create(:pilotage_register_item, project:, kind: "risk", probability: 5, impact: 5)

    result = described_class.new(project).call

    expect(result.reporting).to eq("red")
    expect(result.risk).to eq("red")
    expect(result.computed_health).to eq("red")
    expect(result.false_green).to be(true)
  end

  it "turns the schedule signal red when a milestone is more than 15 days late" do
    create(:pilotage_milestone_review, project:, key: "P2", planned_on: Date.current - 20)

    expect(described_class.new(project).call.schedule).to eq("red")
  end
end
