# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-bolt/util/bolt'
require 'vagrant-bolt/config'

describe VagrantBolt::Util::Bolt do
  include VagrantBolt::Util::Bolt
  let(:config) { VagrantBolt::Config::Bolt.new }
  let(:local_data_path) { '/local/data/path' }
  let(:inventory_path) { "#{local_data_path}/bolt_inventory.yaml" }

  before(:each) do
    config.finalize!
  end

  context 'generating the inventory file' do
    let(:env) { double 'env' }
    let(:machine) do
      double(
        name: 'machine',
        ssh_info: {
          host: 'machine',
        },
      )
    end
    let(:machine_hash) do
      {
        "config" => {
          "ssh" => {
            "connect-timeout" => "30",
            "host-key-check" => false,
            "port" => "22",
            "user" => "vagrant",
            "password" => "foo",
            "private-key" => "bar",
            "run-as" => "root",
          },
          "transport" => "ssh",
        },
        "uri" => "ssh://machine:22",
        "facts" => { 'a' => 'b' },
        "alias" => 'machine',
        "name" => 'somename',
        "vars" => { 'foo' => 'bar' },
        "features" => ['foo'],
      }
    end
    let(:config_hash) { { 'config' => { 'a' => 'b' } } }
    let(:node_hash) do
      {
        'targets' => [machine_hash],
        'config' => config_hash['config'],
      }
    end
    before(:each) do
      config.password = 'foo'
      config.run_as = 'root'
      config.port = '22'
      config.private_key = 'bar'
      config.connect_timeout = '30'
      config.host_key_check = false
      config.user = 'vagrant'
      config.facts = { 'a' => 'b' }
      config.features = ['foo']
      config.vars = { 'foo' => 'bar' }
      config.machine_name = 'somename'
      config.finalize!
      allow(machine).to receive_message_chain("config.bolt.inventory_config").and_return(config.inventory_config)
      allow(machine).to receive_message_chain("config.vm.communicator").and_return(:ssh)
      allow(machine).to receive_message_chain('communicate.ready?').and_return(true)
      allow(env).to receive_message_chain("vagrantfile.config.bolt.inventory_config").and_return(config_hash)
      allow(env).to receive(:active_machines).and_return(['machine'])
      allow(env).to receive(:machine).and_return(machine)
      allow_any_instance_of(VagrantBolt::Util::Machine).to receive(:machines_in_environment).with(env).and_return([machine])
      allow_any_instance_of(VagrantBolt::Util::Machine).to receive(:running?).with(machine).and_return(true)
    end

    it 'creates a node group hash' do
      expect(subject.generate_node_hash(machine)).to eq(machine_hash)
    end

    it 'creates an inventory hash with groups' do
      expect(subject.generate_inventory_hash(env)).to eq(node_hash)
    end
  end

  context 'create bolt command' do
    before(:each) do
      config.bolt_exe = 'bolt'
      config.command = 'task'
      config.name = 'foo'
      config.finalize!
    end

    it 'contains the bolt command' do
      config.node_list = 'ssh://test:22'
      config.user = 'user'
      config.finalize!
      expected = "bolt task run 'foo' --user \'user\' --inventoryfile '#{inventory_path}' --targets \'ssh://test:22\'"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end

    it 'appends args to the end of the command' do
      config.args = 'bar'
      config.finalize!
      expected = "bolt task run 'foo' --inventoryfile '#{inventory_path}' bar"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end

    it 'adds directories to the command' do
      config.modulepath = 'baz'
      config.project = 'foo'
      config.finalize!
      expected = "bolt task run 'foo' --modulepath 'baz' --project 'foo' --inventoryfile '#{inventory_path}'"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end

    it 'uses project when boltdir is specified' do
      config.modulepath = 'baz'
      config.boltdir = 'foo'
      config.finalize!
      expected = "bolt task run 'foo' --modulepath 'baz' --project 'foo' --inventoryfile '#{inventory_path}'"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end

    it 'adds booleans to the command' do
      config.verbose = true
      config.ssl = false
      config.finalize!
      expected = "bolt task run 'foo' --no-ssl --verbose --inventoryfile '#{inventory_path}'"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end

    it 'adds params to the command' do
      config.params = { 'a' => 'b' }
      config.finalize!
      expected = "bolt task run 'foo' --params '{\"a\":\"b\"}' --inventoryfile '#{inventory_path}'"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end

    it 'adds debug, verbose, and noop when true' do
      config.debug = true
      config.verbose = true
      config.noop = true
      config.finalize!
      expected = "bolt task run 'foo' --verbose --debug --noop --inventoryfile '#{inventory_path}'"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end

    it 'run_as is not included' do
      config.node_list = 'ssh://test:22'
      config.user = 'user'
      config.run_as = 'foo'
      config.finalize!
      expected = "bolt task run 'foo' --user \'user\' --inventoryfile '#{inventory_path}' --targets \'ssh://test:22\'"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end

    it 'debug, verbose, and noop are omitted when false' do
      config.debug = false
      config.verbose = false
      config.noop = false
      config.finalize!
      expected = "bolt task run 'foo' --inventoryfile '#{inventory_path}'"
      expect(subject.generate_bolt_command(config, inventory_path)).to eq(expected)
    end
  end
end
