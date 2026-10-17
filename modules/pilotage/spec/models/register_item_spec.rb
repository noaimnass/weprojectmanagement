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

RSpec.describe Pilotage::RegisterItem do
  let(:project) { create(:project) }

  it "assigns sequential references per kind and project" do
    first = create(:pilotage_register_item, project:, kind: "risk")
    second = create(:pilotage_register_item, project:, kind: "risk")
    action = create(:pilotage_register_item, project:, kind: "action")

    expect([first.reference, second.reference, action.reference]).to eq(%w[R-001 R-002 A-001])
  end

  it "computes criticality from probability and impact" do
    item = build(:pilotage_register_item, probability: 4, impact: 4)
    expect(item.criticality).to eq(16)
    expect(item.criticality_level).to eq("red")
  end

  it "sets closed_on when closed and clears it when reopened" do
    item = create(:pilotage_register_item, project:)
    item.update!(status: "closed")
    expect(item.closed_on).to eq(Date.current)
    item.update!(status: "open")
    expect(item.closed_on).to be_nil
  end
end
