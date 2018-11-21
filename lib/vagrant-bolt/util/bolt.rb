# frozen_string_literal: true

require_relative 'machine'

module VagrantBolt::Util
  module Bolt
    # Bolt Centric Utility Functions

    # Create a bolt command from the config
    # @param [Object] config The config objects
    # @param [String] inventory_path The path of the inventory file
    # @return [String] The bolt command
    def self.create_bolt_command(config, inventory_path = nil)
      command = []
      command << config.bolt_command
      command << "#{config.type} run \'#{config.name}\'"

      config.instance_variables_hash.each do |key, value|
        next if key.to_s.start_with?('__')
        next if config.blacklist.include?(key)
        next if value.nil?

        key = key.tr('_', '-')
        case value
        when TrueClass, FalseClass
          # Verbose and debug do not have --no flags so exclude them
          next if ['verbose', 'debug'].include?(key) && !value

          arg = value ? "--#{key}" : "--no-#{key}"
          command << arg
        when String
          command << "--#{key} \'#{value}\'"
        when Hash
          command << "--#{key} \'#{value.to_json}\'" unless value.empty?
        end
      end

      command << "--inventoryfile \'#{inventory_path}\'" unless inventory_path.nil?
      command << "--nodes \'#{config.node_list}\'" unless config.node_list.nil?
      command << config.args unless config.args.nil?
      command.flatten.join(" ")
    end

    # Generate a bolt inventory hash for the environment
    # @param [Object] env The env object
    # @return [Hash] The hash of config options for the inventory.yaml
    def self.generate_inventory_hash(env)
      inventory = { 'groups' => [] }
      inventory.merge!(env.vagrantfile.config.bolt.inventory_config.compact)
      VagrantBolt::Util::Machine.nodes_in_environment(env).each do |vm|
        next unless VagrantBolt::Util::Machine.running?(vm)

        inventory['groups'] << generate_node_group(vm)
      end
      inventory.compact
    end

    # Generate a bolt inventory group hash from the VM config
    # @param [Object] machine The machine object
    # @return [Hash] The hash of config options for the VM
    def self.generate_node_group(machine)
      # Only call ssh_info once
      node_group = {}
      node_group['name'] = machine.name.to_s

      vm_ssh_info = machine.ssh_info
      return node_group if vm_ssh_info.nil?

      config_transport = {}
      if VagrantBolt::Util::Machine.windows?(machine)
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
      config_transport.merge!(machine_config['config'][transport]) if machine_config.dig('config', transport)
      node_group['config'] = {}
      node_group['config'][transport] = config_transport.compact
      node_group['nodes'] = ["#{transport}://#{vm_ssh_info[:host]}:#{node_group['config'][transport]['port']}"]
      node_group['config']['transport'] = transport
      machine_config.each do |key, value|
        next if key == 'config' || value.nil? || value.empty?

        node_group[key] = value
      end
      node_group.compact
    end

    # Return the path to the inventory file
    # @param [Object] The environment
    # @return [String] The path to the inventory file
    def self.inventory_file(env)
      File.join(env.local_data_path, 'bolt_inventory.yaml')
    end

    # Update and write the inventory file for the current running machines
    # @param [Object] env The envionment object
    # @return path to the inventory file
    def self.update_inventory_file(env)
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
end
