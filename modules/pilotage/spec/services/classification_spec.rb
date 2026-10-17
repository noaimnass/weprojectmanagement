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

RSpec.describe Pilotage::Classification do
  it "classifies by budget thresholds expressed in units" do
    expect(described_class.classify(budget_total: 12_000_000, entities_count: 1)).to eq("A")
    expect(described_class.classify(budget_total: 2_000_000, entities_count: 1)).to eq("B")
    expect(described_class.classify(budget_total: 300_000, entities_count: 1)).to eq("C")
  end

  it "upgrades the class when enough entities are involved" do
    expect(described_class.classify(budget_total: 3_000_000, entities_count: 4)).to eq("A")
    expect(described_class.classify(budget_total: 1_000_000, entities_count: 3)).to eq("B")
  end

  it "evaluates eligibility criteria independently" do
    eligibility = described_class.eligibility(budget: 100_000, months: 4, entities: 1)
    expect(eligibility).to eq(budget: false, duration: true, entities: false)
  end

  it "returns the cadence of each class" do
    expect(described_class.cadence_days("A")).to eq(7)
    expect(described_class.cadence_days("B")).to eq(15)
    expect(described_class.cadence_days("C")).to eq(31)
  end
end
