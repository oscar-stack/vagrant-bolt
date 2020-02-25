# frozen_string_literal: true

require_relative 'util/bolt'
require_relative 'util/config'
require_relative 'util/machine'

class VagrantBolt::Runner
  def initialize(env, machine, boltconfig = nil)
    @env = env
    @machine = machine
    @boltconfig = boltconfig.nil? ? VagrantBolt::Config::Bolt.new : boltconfig
    @inventory_path = VagrantBolt::Util::Bolt.inventory_file(@env)
  end

  # Run a bolt task or plan
  # @param [Symbol, String] command The command of bolt to run; task or plan
  # @param [String] name The name of the bolt task or plan to run
  # @param [Hash] args A optional hash of bolt config overrides. No merging will be done with the overrides
  # @example run('task', 'facts', {node_list: "machinename"})
  def run(command, name, **args)
    @boltconfig = setup_overrides(command, name, **args)
    # Don't run anything if there are nodes to run it on
    # TODO: Gate this in a more efficient manner. It is possible to run plans without a node list.
    return if @boltconfig.node_list.nil?

    @inventory_path = VagrantBolt::Util::Bolt.update_inventory_file(@env)
    validate
    command = VagrantBolt::Util::Bolt.generate_bolt_command(@boltconfig, @inventory_path)
    VagrantBolt::Util::Machine.run_command(command, @machine.ui)
  end

  private

  # Set up config overrides
  # @param [Symbol, String] command The command of bolt to run; task or plan
  # @param [String] name The name of the bolt task or plan to run
  # @param [Hash] args A optional hash of bolt config overrides; {run_as: "vagrant"}
  # @return [Object] Bolt config with ssh info populated
  def setup_overrides(command, name, **args)
    config = @boltconfig.dup
    config.command = command
    config.name = name
    # Merge the root config to get the defaults for the environment
    config = VagrantBolt::Util::Config.merge_config(config, @env.vagrantfile.config.bolt)
    # Add any additional arguments to the config object
    config.set_options(args) unless args.nil?
    # Configure the node_list based on the config
    config.node_list ||= [config.nodes - config.excludes].flatten.join(',') unless config.nodes.empty? || config.nodes.to_s.casecmp("all").zero?
    config.node_list ||= [VagrantBolt::Util::Machine.machines_in_environment(@env).map(&:name) - config.excludes].flatten.join(',') if config.nodes.to_s.casecmp("all").zero?
    config.node_list ||= @machine.name.to_s unless config.excludes.include?(@machine.name.to_s)

    # Ensure these are absolute paths to allow for running vagrant commands outside of the root dir
    config.modulepath = VagrantBolt::Util::Config.relative_path(config.modulepath, @env.root_path)
    config.boltdir = VagrantBolt::Util::Config.relative_path(config.boltdir, @env.root_path)

    config
  end

  # Validate the config object for configuration issues
  # Print and raise an exception if errors exist
  def validate
    errors = {}
    errors.merge!(@boltconfig.validate(@machine))
    errors.merge!(validate_config)

    errors.keys.each do |key|
      errors.delete(key) if errors[key].empty?
    end

    # rubocop:disable Style/GuardClause
    if errors && !errors.empty?
      raise Vagrant::Errors::ConfigInvalid,
            errors: Vagrant::Util::TemplateRenderer.render(
              "config/validation_failed",
              errors: errors,
            )
    end
    # rubocop:enable Style/GuardClause
  end

  # Validate a bolt config object for logical errors
  def validate_config
    errors = []
    errors << I18n.t('vagrant-bolt.config.bolt.errors.command_not_specified') if @boltconfig.command.nil?
    errors << I18n.t('vagrant-bolt.config.bolt.errors.no_task_or_plan') if @boltconfig.name.nil?
    { "Bolt" => errors }
  end
end
