# frozen_string_literal: true

require 'vagrant'
require_relative 'version'

raise "vagrant-bolt version #{VagrantBolt::VERSION} requires Vagrant 2.2 or later" if Vagrant::VERSION < "2.2.0"

class VagrantBolt::Plugin < Vagrant.plugin('2')
  name 'bolt'

  description <<-DESC
    Vagrant provisioning with Puppet Bolt
  DESC

  config(:bolt) do
    require_relative 'config'
    VagrantBolt::Config::Global
  end

  config(:bolt, :provisioner) do
    require_relative 'config'
    VagrantBolt::Config::Bolt
  end

  provisioner(:bolt) do
    require_relative 'provisioner'
    VagrantBolt::Provisioner
  end

  command(:bolt) do
    require_relative 'command'
    VagrantBolt::Command
  end

  def self.config_builder_hook
    require_relative 'config_builder'
  end
end
