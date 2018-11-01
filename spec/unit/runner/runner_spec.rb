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
    end
    VAGRANTFILE
    env.create_vagrant_env
  end
  let(:machine) {iso_env.machine(:server, :dummy)}
  let(:runner) {double :runner}
  let(:config) {VagrantBolt::Config.new}
  let(:subprocess_result) do
    double("subprocess_result").tap do |result|
      allow(result).to receive(:exit_code).and_return(0)
      allow(result).to receive(:stderr).and_return("")
    end
  end
  before(:each) do
    allow(machine).to receive(:env).and_return(:iso_env)
    allow(machine).to receive(:ssh_info).and_return({
      :host => 'foo',
      :port => '22',
      :username => 'user',
      :private_key_path => ['path'],
      :verify_host_key => true,
    })
    config.finalize!
  end

  context 'setup_overrides' do
    before(:each) do
      allow_any_instance_of(VagrantBolt::Util).to receive(:all_node_list).with(iso_env).and_return('nodes')
    end
    it 'adds the type and name to the config' do
      result = subject.send(:setup_overrides, 'task', 'foo')
      expect(result.type).to eq('task')
      expect(result.name).to eq('foo')
    end

    it 'adds the ssh_info to the config' do
      result = subject.send(:setup_overrides, 'task', 'foo')
      expect(result.nodes).to eq('ssh://foo:22')
      expect(result.username).to eq('user')
      expect(result.privatekey).to eq('path')
      expect(result.hostkeycheck).to eq(true)
    end

    it 'adds all nodes when all is specified' do
      result = subject.send(:setup_overrides, 'task', 'foo', {:nodes => 'all'})
      expect(result.nodes).to eq('nodes')
    end

    it 'does not override specified ssh settings' do
      config.nodes = 'test:22'
      config.username = 'root'
      config.finalize!
      result = subject.send(:setup_overrides, 'task', 'foo')
      expect(result.nodes).to eq('test:22')
      expect(result.username).to eq('root')
    end

    it 'allows for specifying additional args' do
      result = subject.send(:setup_overrides, 'task', 'foo', {:password => 'foo'})
      expect(result.password).to eq('foo')
    end

  end
  context 'run_bolt' do
    let(:options) { {:notify => [:stdout, :stderr], :env => {PATH: nil}} }
    before(:each) do
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)
    end
    it 'creates a shell execution' do
      config.type = 'task'
      config.name = 'foo'
      config.nodes = 'ssh://test:22'
      config.finalize!
      command = "bolt task run 'foo' --no-host-key-check --modulepath 'modules' --boltdir '.' -n 'ssh://test:22'"
      expect(Vagrant::Util::Subprocess).to receive(:execute).with('bash', '-c', command, options).and_return(subprocess_result)
      subject.send(:run_bolt)
    end
  end
  context 'run' do
    before(:each) do
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)
    end

    it 'raises an exception if the type is not specified' do
      expect{subject.run(nil, 'foo')}.to raise_error(Vagrant::Errors::ConfigInvalid, /No type set/)
    end

    it 'raises an exception if the name is not specified' do
      expect{subject.run('task', nil)}.to raise_error(Vagrant::Errors::ConfigInvalid, /No name set/)
    end
  end
end
