# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-bolt/util'
require 'vagrant-bolt/config'

describe VagrantBolt::Util do
  include VagrantBolt::Util
  let(:global) { VagrantBolt::Config.new }
  let(:local) { VagrantBolt::Config.new }

  before(:each) do
    global.finalize!
    local.finalize!
  end

  context 'merging local and global configs' do
    it 'uses global if local is unset' do
      global.name = 'foo'
      global.finalize!
      result = merge_config(local, global)
      expect(result.name).to eq('foo')
    end

    it 'uses local if local and global are both set' do
      global.name = 'foo'
      global.finalize!
      local.name = 'bar'
      local.finalize!
      result = merge_config(local, global)
      expect(result.name).to eq('bar')
    end

    it 'does not allow nil overrides' do
      global.name = 'foo'
      global.finalize!
      local.name = nil
      local.finalize!
      result = merge_config(local, global)
      expect(result.name).to eq('foo')
    end

    it 'merges arrays' do
      global.dependencies = ['foo']
      global.finalize!
      local.dependencies = ['bar']
      local.finalize!
      result = merge_config(local, global)
      expect(result.dependencies).to eq(['bar', 'foo'])
    end
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
            "host-key-check" => false,
            "password" => "foo",
            "port" => "22",
            "private-key" => "bar",
            "run-as" => "root",
            "user" => "vagrant",
          },
          "winrm" => {
            "password" => "foo",
            "port" => "22",
            "run-as" => "root",
            "ssl" => false,
            "ssl-verify" => false,
            "user" => "vagrant",
          },
          "transport" => "ssh",
        },
        "name" => "machine",
        "nodes" => ["ssh://machine:22"],
      }
    end
    let(:config_hash) { 'nothing' }
    let(:group_hash) do
      {
        'groups' => [machine_hash],
        'config' => config_hash,
      }
    end
    before(:each) do
      local.password = 'foo'
      local.run_as = 'root'
      local.port = '22'
      local.private_key = 'bar'
      local.host_key_check = false
      local.user = 'vagrant'
      local.finalize!
      allow(machine).to receive_message_chain("config.bolt.inventory_config").and_return(local.inventory_config)
      allow(machine).to receive_message_chain("config.vm.communicator").and_return(:ssh)
      allow(env).to receive_message_chain("vagrantfile.config.bolt.inventory_config").and_return(config_hash)
      allow_any_instance_of(VagrantBolt::Util).to receive(:nodes_in_environment).with(env).and_return([machine])
      allow_any_instance_of(VagrantBolt::Util).to receive(:running?).with(machine).and_return(true)
    end

    it 'creates a node group hash' do
      expect(generate_node_group(machine)).to eq(machine_hash)
    end

    it 'creates an inventory hash with groups' do
      expect(generate_inventory_hash(env)).to eq(group_hash)
    end
  end
end
