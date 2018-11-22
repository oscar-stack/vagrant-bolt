# frozen_string_literal: true

require_relative 'machine'

module VagrantBolt::Util
  module Bolt
    # Bolt Centric Utility Functions

    # Create a bolt command from the config
    # @param [Object] config The config objects
    # @param [String] inventory_path The path of the inventory file
    # @return [String] The bolt command
    def self.generate_bolt_command(config, inventory_path = nil)
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
      ssh_info = machine.ssh_info
      return node_group if ssh_info.nil?

      node_group['name'] = machine.name.to_s
      machine_config = machine.config.bolt.inventory_config
      node_group['config'] = {}
      transport = VagrantBolt::Util::Machine.windows?(machine) ? 'winrm' : 'ssh'
      node_group['config'][transport] = machine_transport_hash(machine, machine_config, ssh_info).compact
      node_group['config']['transport'] = transport
      node_group['nodes'] = ["#{transport}://#{ssh_info[:host]}:#{node_group['config'][transport]['port']}"]
      machine_config.each do |key, value|
        next if key == 'config' || value.nil? || value.empty?

        node_group[key] = value
      end
      node_group.compact
    end

    # Return a transport config hash for a node
    # @param [Object] machine The machine
    # @param [Hash] machine_config A hash of the machine config options
    # @param [Hash] ssh_info The ssh hash for the machine
    def self.machine_transport_hash(machine, machine_config = {}, ssh_info = nil)
      config = {}
      if VagrantBolt::Util::Machine.windows?(machine)
        transport = 'winrm'
        config['ssl'] = (machine.config.winrm.transport == :ssl)
        config['ssl_verify'] = machine.config.winrm.ssl_peer_verification
        config['port'] = machine.config.winrm.port
        config['user'] = machine.config.winrm.username
        config['password'] = machine.config.winrm.password
      else
        transport = 'ssh'
        config['private-key'] = ssh_info[:private_key_path][0] unless ssh_info[:private_key_path].nil?
        config['host-key-check'] = (ssh_info[:verify_host_key] == true)
        config['port'] = ssh_info[:port]
        config['user'] = ssh_info[:username]
        config['password'] = ssh_info[:password]
      end
      config.merge!(machine_config['config'][transport]) if machine_config.dig('config', transport)
      config
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
