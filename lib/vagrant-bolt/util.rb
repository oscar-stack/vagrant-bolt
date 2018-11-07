# frozen_string_literal: true

module VagrantBolt::Util
  # Utility Functions

  # Merge config objects overriding Nil and UNSET_VALUE
  # Since the configs have been finalized they will have `nil` values
  # Arrays will be merged and override parent non arrays
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
          value = (value + res_value).uniq if res_value.is_a? Array
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
  # @param [Array<String>, String] includes Array of machine names to include, or ALL for all nodes
  # @param [Array<String>] excludes Array of machine names to exclude
  # @return [String]
  def node_uri_list(env, includes = [], excludes = [])
    all_nodes_enabled = includes.to_s.casecmp("all").zero?
    return nil if !all_nodes_enabled && includes.empty?

    nodes_in_environment(env).map { |vm|
      next unless all_nodes_enabled || includes.include?(vm.name.to_sym) || includes.include?(vm.name.to_s)
      next if excludes.include?(vm.name.to_sym) || excludes.include?(vm.name.to_s) || !running?(vm)

      # Only call ssh_info once
      vm_ssh_info = vm.ssh_info
      if windows?(vm)
        "winrm://#{vm.config.winrm.host}:#{vm.config.winrm.port}" unless vm_ssh_info.nil?
      else
        "ssh://#{vm_ssh_info[:host]}:#{vm_ssh_info[:port]}" unless vm_ssh_info.nil?
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
  # @param [String, Symbol] name The name of the machine in the environment
  # @return [Object, nil] The object or nil if it is not found
  def machine_by_name(env, name)
    vm = env.active_machines.find { |m| m[0] == name.to_sym }
    env.machine(*vm) unless vm.nil?
  rescue Vagrant::Errors::MachineNotFound
    nil
  end

  # Generate a bolt inventory hash for the environment
  # @param [Object] env The env object
  # @return [Hash] The hash of config options for the inventory.yaml
  def generate_inventory_hash(env)
    inventory = { 'groups' => [] }
    nodes_in_environment(env).each do |vm|
      next unless running?(vm)

      inventory['groups'] << generate_node_group(vm)
    end
    inventory['config'] = env.vagrantfile.config.bolt.config_hash
    inventory
  end

  # Generate a bolt inventory group hash from the VM config
  # @param [Object] machine The machine object
  # @return [Hash] The hash of config options for the VM
  def generate_node_group(machine)
    # Only call ssh_info once
    vm_ssh_info = machine.ssh_info
    node_group = {}
    node_group['name'] = machine.name.to_s
    node_group['nodes'] = [vm_ssh_info[:host]]
    node_group['config'] = machine.config.bolt.config_hash
    if windows?(@machine)
      transport = 'winrm'
      node_group['config'][transport] ||= {}
      node_group['config'][transport]['ssl'] ||= (machine.config.bolt.ssl == true)
      node_group['config'][transport]['ssl_verify'] ||= (machine.config.bolt.ssl_verify == true)
    else
      transport = 'ssh'
      node_group['config'][transport] ||= {}
      node_group['config'][transport]['private-key'] ||= vm_ssh_info[:private_key_path][0]
      node_group['config'][transport]['host-key-check'] ||= (vm_ssh_info[:verify_host_key] == true)
    end
    node_group['config']['transport'] = transport
    node_group
  end
end
