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
end
