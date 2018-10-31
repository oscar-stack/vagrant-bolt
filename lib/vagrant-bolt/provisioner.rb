require 'vagrant'
require 'vagrant/errors'
require 'vagrant-bolt/util'

class VagrantBolt::Provisioner < Vagrant.plugin('2', :provisioner)
  # Provision VMs with Bolt
  # Creates a trigger for each bolt provioner

  def configure(root_config)
    merge_root_config(root_config.bolt)
    #TODO: validate_config for type and name
    #validate_config
  end

  def provision
    runner = VagrantBolt::Runner.new(@machine.env, @machine, @config)
    runner.run(@config.type, @config.name)
  end

  def cleanup
    # We don't do any clean up for this provisioner
  end

  private

  include VagrantBolt::Util

  # Merge the local and root_config settings into @config
  # Allow for setting defaults in the root_config. We merge them here.
  # @param [Object] root_bolt_config A bolt config object from the root_config
  def merge_root_config(root_bolt_config)
    result = config.class.new
    result = merge_config(result, root_bolt_config)
    result = merge_config(result, config)
    result.finalize!
    @config = result
  end
end
