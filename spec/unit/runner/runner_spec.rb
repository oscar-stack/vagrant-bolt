# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-bolt/runner'
require 'vagrant-bolt/config'

describe VagrantBolt::Runner do
  include_context 'vagrant-unit'
  subject { described_class.new(iso_env, machine, config) }

  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile <<-VAGRANTFILE
    Vagrant.configure('2') do |config|
      config.vm.define :server
      config.vm.define :server2
    end
    VAGRANTFILE
    env.create_vagrant_env
  end
  let(:machine) { iso_env.machine(:server, :dummy) }
  let(:machine2) { iso_env.machine(:server2, :dummy) }
  let(:runner) { double :runner }
  let(:config) { VagrantBolt::Config::Bolt.new }
  let(:subprocess_result) do
    double("subprocess_result").tap do |result|
      allow(result).to receive(:exit_code).and_return(0)
      allow(result).to receive(:stderr).and_return("")
    end
  end
  let(:root_path) { Dir.getwd }
  let(:local_data_path) { "#{root_path}/.vagrant" }
  let(:inventory_path) { ".vagrant/bolt_inventory.yaml" }
  before(:each) do
    allow(VagrantBolt::Util::Bolt).to receive(:update_inventory_file).with(iso_env).and_return(inventory_path)
    allow(machine).to receive(:env).and_return(:iso_env)
    allow(machine).to receive(:ssh_info).and_return(
      host: 'foo',
      port: '22',
      username: 'user',
      private_key_path: ['path'],
      verify_host_key: true,
    )
    config.finalize!
  end

  context 'setup_overrides' do
    before(:each) do
      allow(VagrantBolt::Util::Machine).to receive(:nodes_in_environment).with(iso_env).and_return([machine, machine2])
    end
    it 'adds the command and name to the config' do
      result = subject.send(:setup_overrides, 'task', 'foo')
      expect(result.command).to eq('task')
      expect(result.name).to eq('foo')
    end

    it 'uses the server name for the nodes' do
      result = subject.send(:setup_overrides, 'task', 'foo')
      expect(result.node_list).to eq('server')
    end

    it 'allows for using multiple nodes' do
      config.nodes = ['server', 'server2']
      config.finalize!
      result = subject.send(:setup_overrides, 'task', 'foo')
      expect(result.node_list).to eq('server,server2')
    end

    it 'adds all nodes when "all" is specified' do
      config.nodes = 'all'
      config.finalize!
      result = subject.send(:setup_overrides, 'task', 'foo')
      expect(result.node_list).to eq('server,server2')
    end

    it 'does not override specified ssh settings' do
      config.node_list = 'ssh://test:22'
      config.user = 'root'
      config.finalize!
      result = subject.send(:setup_overrides, 'task', 'foo')
      expect(result.node_list).to eq('ssh://test:22')
      expect(result.user).to eq('root')
    end

    it 'allows for specifying additional args' do
      result = subject.send(:setup_overrides, 'task', 'foo', password: 'foo')
      expect(result.password).to eq('foo')
    end
  end

  context 'run' do
    let(:options) { { notify: [:stdout, :stderr], env: { PATH: nil } } }
    before(:each) do
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)
      allow(iso_env).to receive(:root_path).and_return(root_path)
      allow(iso_env).to receive(:local_data_path).and_return(local_data_path)
    end

    it 'does not raise an exeption when all parameters are specified' do
      expect { subject.run('task', 'foo') }.to_not raise_error
    end

    it 'raises an exception if the command is not specified' do
      expect { subject.run(nil, 'foo') }.to raise_error(Vagrant::Errors::ConfigInvalid, %r{No command set})
    end

    it 'raises an exception if the name is not specified' do
      expect { subject.run('task', nil) }.to raise_error(Vagrant::Errors::ConfigInvalid, %r{No name set})
    end

    it 'creates a shell execution' do
      config.bolt_exe = 'bolt'
      config.boltdir = '.'
      config.node_list = 'ssh://test:22'
      config.finalize!
      command = "bolt task run 'foo' --boltdir '.' --inventoryfile '#{inventory_path}' --nodes 'ssh://test:22'"
      expect(Vagrant::Util::Subprocess).to receive(:execute).with('bash', '-c', command, options).and_return(subprocess_result)
      subject.run('task', 'foo')
    end
  end
end
