require 'vagrant'
require 'vagrant/errors'

class VagrantBolt::Provisioner::Bolt < Vagrant.plugin('2', :provisioner)
  # Provision VMs with Bolt
  # @since 0.0.1

  def configure(root_config)
  # Do any root level config needed to the VM
  end

  def provision
    provision_task unless config.task.nil?
    provision_plan unless config.plan.nil?
  end

  def cleanup

  end

  private

  def provision_task
    puts "Provisioning Task"
  end

  def provision_plan
    puts "Provisioning Plan"
  end
end
