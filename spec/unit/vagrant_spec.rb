# frozen_string_literal: true

require 'spec_helper'
describe "Vagrant" do
  it "loads with the bolt plugin" do
    env = Vagrant::Environment.new
    expect(env.cli("-h")).to eq(0)
  end
end
