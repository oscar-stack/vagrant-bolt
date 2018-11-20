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
    result.finalize!
    result
  end

  # Run a command locally with an execute
  # @param [String] The command to run
  # @param [Object] the UI object to write to
  def run_command(command, localui)
    localui.info(
      I18n.t('vagrant-bolt.provisioner.bolt.info.running_bolt',
             command: command),
    )

    # TODO: Update this so it works on windows platforms
    Vagrant::Util::Subprocess.execute(
      'bash',
      '-c',
      command,
      notify: [:stdout, :stderr],
      env: { PATH: ENV["VAGRANT_OLD_ENV_PATH"] },
    ) do |io_name, data|
      if io_name == :stdout
        localui.info data
      elsif io_name == :stderr
        localui.warn data
      end
    end
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

  # Return if the guest is windows. This only works for online machines
  # @param [Object] machine The machine
  # @return [Boolean]
  def windows?(machine)
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
    inventory['config'] = env.vagrantfile.config.bolt.inventory_config
    inventory
  end

  # Generate a bolt inventory group hash from the VM config
  # @param [Object] machine The machine object
  # @return [Hash] The hash of config options for the VM
  def generate_node_group(machine)
    # Only call ssh_info once
    node_group = {}
    node_group['name'] = machine.name.to_s

    vm_ssh_info = machine.ssh_info
    return node_group if vm_ssh_info.nil?

    config_transport = {}
    if windows?(machine)
      transport = 'winrm'
      config_transport['ssl'] = (machine.config.winrm.transport == :ssl)
      config_transport['ssl_verify'] = machine.config.winrm.ssl_peer_verification
      config_transport['port'] = machine.config.winrm.port
      config_transport['user'] = machine.config.winrm.username
      config_transport['password'] = machine.config.winrm.password
    else
      transport = 'ssh'
      config_transport['private-key'] = vm_ssh_info[:private_key_path][0] unless vm_ssh_info[:private_key_path].nil?
      config_transport['host-key-check'] = (vm_ssh_info[:verify_host_key] == true)
      config_transport['port'] = vm_ssh_info[:port]
      config_transport['user'] = vm_ssh_info[:username]
      config_transport['password'] = vm_ssh_info[:password]
    end
    machine_config = machine.config.bolt.inventory_config
    config_transport.merge!(machine_config[transport]) unless machine_config.empty?
    node_group['config'] = {}
    node_group['config'][transport] = config_transport.compact
    node_group['nodes'] = ["#{transport}://#{vm_ssh_info[:host]}:#{node_group['config'][transport]['port']}"]
    node_group['config']['transport'] = transport
    node_group.compact
  end

  # Return the path to the inventory file
  # @param [Object] The environment
  # @return [String] The path to the inventory file
  def inventory_file(env)
    File.join(env.local_data_path, 'bolt_inventory.yaml')
  end

  # Update and write the inventory file for the current running machines
  # @param [Object] env The envionment object
  # @return path to the inventory file
  def update_inventory_file(env)
    inventory = generate_inventory_hash(env).to_yaml
    inventory_file = Pathname.new(inventory_file(env))
    # TODO: This lock should be global
    lock = Mutex.new
    lock.synchronize do
      if !File.exist?(inventory_file) || (inventory != File.read(inventory_file))
        begin
          inventory_tmpfile = Tempfile.new('.vagrant_bolt_inventory', env.local_data_path)
          inventory_tmpfile.write(inventory)
          inventory_tmpfile.close
          File.rename(inventory_tmpfile.path, inventory_file)
        ensure
          inventory_tmpfile.close
          inventory_tmpfile.unlink
        end
      end
    end
    inventory_file
  end
end
