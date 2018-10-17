module VagrantBolt::Util
  # Utility Functions

  # Merge config objects overriding Nil and UNSET_VALUE
  # Since the configs have been finalized they will have `nil` values
  # instead of UNSET_VALUE
  # @param [Object] local The local config object
  # @param [Object] other The other config object
  # @return [Object] a merged result with local overriding other
  def merge_config(local, other)
    result = local.class.new
    [local, other].each do |obj|
      obj.instance_variables.each do |key|
        value = obj.instance_variable_get(key)
        result.instance_variable_set(key, value) if value != Vagrant::Plugin::V2::Config::UNSET_VALUE and value != nil
      end
    end
    return result
  end

  # Generate a list of active machines in the environment
  # @param [Object] env The Environment
  # @return [Array[Object]]
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
      unless excludes.include?(vm.name.to_s)
        "#{vm.ssh_info[:host]}:#{vm.ssh_info[:port]}" unless vm.ssh_info.nil?
      end
    }.compact.join(",")
  end
end
