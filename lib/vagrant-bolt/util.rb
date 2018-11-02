# frozen_string_literal: true

module VagrantBolt::Util
  # Utility Functions

  # Merge config objects overriding Nil and UNSET_VALUE
  # Since the configs have been finalized they will have `nil` values
  # Arrays will be merged
  # instead of UNSET_VALUE
  # @param [Object] local The local config object
  # @param [Object] other The other config object
  # @return [Object] a merged result with local overriding other
  def merge_config(local, other)
    result = local.class.new
    [other, local].each do |obj|
      obj.instance_variables.each do |key|
        value = obj.instance_variable_get(key)
        if value.is_a? Array
          res_value = result.instance_variable_get(key)
          value = (value + res_value).uniq unless res_value.nil?
        end
        result.instance_variable_set(key, value) if value != Vagrant::Plugin::V2::Config::UNSET_VALUE && !value.nil?
      end
    end
    result
  end

  # Generate a list of active machines in the environment
  # @param [Object] env The Environment
  # @return [Array<Object>]
  def nodes_in_environment(env)
    env.active_machines.map { |vm|
      begin
        env.machine(*vm)
      rescue Vagrant::Errors::MachineNotFound
        nil
      end
    }.compact
  end

  # Generate a CSV list of node:port addresses for all active nodes in the environment
  # @param [Object] env The Enviornment
  # @param [Array[String]] excludes Array of machine names to exclude
  # @return [String]
  def all_node_list(env, excludes = [])
    nodes_in_environment(env).map { |vm|
      unless excludes.include?(vm.name.to_s) || !running?(vm)
        if windows?(vm)
          "winrm://#{vm.config.winrm.host}:#{vm.config.winrm.port}" unless vm.ssh_info.nil?
        else
          "ssh://#{vm.ssh_info[:host]}:#{vm.ssh_info[:port]}" unless vm.ssh_info.nil?
        end
      end
    }.compact.join(",")
  end

  # Return if the guest is windows. This only works for online machines
  # @param [Object] machine The machine
  # @return [Boolean]
  def windows?(machine)
    # [:winrm, :winssh].include?(machine.config.vm.communicator)
    machine.config.vm.communicator == :winrm
  end

  # Return if the guest is running by checking the communicator
  # @param [Object] machine The machine
  # @return [Boolean]
  def running?(machine)
    # Taken from https://github.com/oscar-stack/vagrant-hosts/blob/master/lib/vagrant-hosts/provisioner/hosts.rb
    machine.communicate.ready?
  rescue Vagrant::Errors::VagrantError
    # WinRM will raise an error if the VM isn't running instead of
    # returning false (hashicorp/vagrant#6356).
    false
  end

  # Get the running machine object by the machine name
  # @param [Object] environment The enviornment to look in
  # @param [String,Symbol] name The name of the machine in the environment
  # @return [Object, nil] The object or nil if it is not found
  def machine_by_name(env, name)
    vm = env.active_machines.find { |m| m[0] == name.to_sym }
    env.machine(*vm) unless vm.nil?
  rescue Vagrant::Errors::MachineNotFound
    nil
  end
end
