require 'vagrant'
require 'vagrant-bolt/version'

if Vagrant::VERSION < "2.1.0"
      raise "vagrant-bolt version #{VagrantBolt::VERSION} requires Vagrant 2.1 or later"
end

module VagrantBolt
  class Plugin < Vagrant.plugin('2')

    name 'bolt'

    description <<-DESC
    Vagrant provisioning with Puppet Bolt
    DESC

  end
end
