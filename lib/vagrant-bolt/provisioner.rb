# frozen_string_literal: true

require 'vagrant'
require 'vagrant/errors'

class VagrantBolt::Provisioner < Vagrant.plugin('2', :provisioner)
  # Provision VMs with Bolt
  # Creates a trigger for each bolt provisioner

  def provision
    runner = VagrantBolt::Runner.new(@machine.env, @machine, @config)
    runner.run(@config.command, @config.name)
  end

  def cleanup
    # We don't do any clean up for this provisioner
  end
end
