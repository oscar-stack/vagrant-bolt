require 'vagrant'
require 'vagrant-bolt/version'

if Vagrant::VERSION < "2.1.0"
      raise "vagrant-bolt version #{VagrantBolt::VERSION} requires Vagrant 2.1 or later"
end

class VagrantBolt::Plugin < Vagrant.plugin('2')

    name 'bolt'

    description <<-DESC
    Vagrant provisioning with Puppet Bolt
    DESC

    config(:bolt) do
      require_relative 'config'
      VagrantBolt::Config::Bolt
    end

    config(:bolt, :provisioner) do
      require_relative 'config'
      VagrantBolt::Config::Bolt
    end

    provisioner(:bolt) do
      require_relative 'provisioner'
      VagrantBolt::Provisioner::Bolt
    end

end
