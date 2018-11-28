# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-bolt/config'
require 'vagrant-bolt/provisioner'

describe VagrantBolt::Provisioner do
  include_context 'vagrant-unit'
  subject { described_class.new(machine, config) }

  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile <<-VAGRANTFILE
    Vagrant.configure('2') do |config|
      config.vm.define :server
    end
    VAGRANTFILE
    env.create_vagrant_env
  end
  let(:machine) { iso_env.machine(:server, :dummy) }
  let(:config) { double :config }
  let(:runner) { double :runner }
  before(:each) do
    allow(machine).to receive(:env).and_return(:iso_env)
    allow(config).to receive(:name).and_return('foo')
    allow(config).to receive(:command).and_return('task')
  end

  context 'provision' do
    before(:each) do
      allow(VagrantBolt::Runner).to receive(:new).with(:iso_env, machine, config).and_return(runner)
      allow(runner).to receive(:run).with('task', 'foo').and_return('runner created')
    end

    it 'creates a new runner' do
      expect(subject.provision).to eq('runner created')
    end
  end
end
