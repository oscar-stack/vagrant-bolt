require 'spec_helper'
describe "Vagrant" do
  it "should load with the bolt plugin" do
    env = Vagrant::Environment.new
    expect(env.cli("-h")).to eq(0)
  end
end
