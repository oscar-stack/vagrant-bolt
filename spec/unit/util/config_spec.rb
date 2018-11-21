# frozen_string_literal: true

require 'spec_helper'
require 'vagrant-bolt/util/config'
require 'vagrant-bolt/config'

describe VagrantBolt::Util::Config do
  let(:global) { VagrantBolt::Config::Bolt.new }
  let(:local) { VagrantBolt::Config::Bolt.new }
  let(:local_data_path) { '/local/data/path' }
  let(:inventory_path) { "#{local_data_path}/bolt_inventory.yaml" }

  before(:each) do
    global.finalize!
    local.finalize!
  end

  context 'merging local and global configs' do
    it 'uses global if local is unset' do
      global.name = 'foo'
      global.finalize!
      result = subject.merge_config(local, global)
      expect(result.name).to eq('foo')
    end

    it 'uses local if local and global are both set' do
      global.name = 'foo'
      global.finalize!
      local.name = 'bar'
      local.finalize!
      result = subject.merge_config(local, global)
      expect(result.name).to eq('bar')
    end

    it 'does not allow nil overrides' do
      global.name = 'foo'
      global.finalize!
      local.name = nil
      local.finalize!
      result = subject.merge_config(local, global)
      expect(result.name).to eq('foo')
    end

    it 'merges arrays' do
      global.excludes = ['foo']
      global.finalize!
      local.excludes = ['bar']
      local.finalize!
      result = subject.merge_config(local, global)
      expect(result.excludes).to eq(['bar', 'foo'])
    end
  end
end
