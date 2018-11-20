# frozen_string_literal: true

require_relative 'util'

class VagrantBolt::Runner
  def initialize(env, machine, boltconfig = nil)
    @env = env
    @machine = machine
    @boltconfig = boltconfig.nil? ? VagrantBolt::Config::Bolt.new : boltconfig
    @inventory_path = File.join(env.local_data_path, 'bolt_inventory.yaml')
  end

  # Run a bolt task or plan
  # @param [Symbol, String] type The type of bolt to run; task or plan
  # @param [String] name The name of the bolt task or plan to run
  # @param [Hash] args A optional hash of bolt config overrides; {run_as: "vagrant"}. No merging will be done with the overrides
  def run(type, name, **args)
    @inventory_path = update_inventory_file(@env) # if @boltconfig.node_list.nil?
    @boltconfig = setup_overrides(type, name, **args)
    # Don't run anything if there are nodes to run it on
    # TODO: Gate this in a more efficient manner. It is possible to run plans without a node list.
    return if @boltconfig.node_list.nil?

    validate
    run_bolt
  end

  private

  include VagrantBolt::Util

  # Set up config overrides
  # @param [Symbol, String] type The type of bolt to run; task or plan
  # @param [String] name The name of the bolt task or plan to run
  # @param [Hash] args A optional hash of bolt config overrides; {run_as: "vagrant"}
  # @return [Object] Bolt config with ssh info populated
  def setup_overrides(type, name, **args)
    config = @boltconfig.dup
    config.type = type
    config.name = name
    # Merge the root config to get the defaults for the environment
    config = merge_config(config, @env.vagrantfile.config.bolt)
    # Add any additional arguments to the config object
    config.set_options(args) unless args.nil?
    # Configure the node_list based on the config
    config.node_list ||= [config.nodes - config.excludes].flatten.join(',') unless config.nodes.empty? || config.nodes.to_s.casecmp("all").zero?
    config.node_list ||= [nodes_in_environment(@env).map(&:name) - config.excludes].flatten.join(',') if config.nodes.to_s.casecmp("all").zero?
    config.node_list ||= @machine.name.to_s unless config.excludes.include?(@machine.name.to_s)

    config
  end

  # Run bolt locally with an execute
  def run_bolt
    command = create_command
    @machine.ui.info(
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
        @machine.ui.info data
      elsif io_name == :stderr
        @machine.ui.warn data
      end
    end
  end

  # Create a bolt command from the config
  # @return [String] The bolt command
  def create_command
    # TODO: add all of the bolt the options and account for Windows Guests
    command = []
    command << @boltconfig.bolt_command
    command << "#{@boltconfig.type} run \'#{@boltconfig.name}\'"

    modulepath = %r{^/.*}.match?(@boltconfig.modulepath) ? @boltconfig.modulepath : "#{@env.root_path}/#{@boltconfig.modulepath}"
    command << "--modulepath \'#{modulepath}\'"
    command << "--tmpdir \'#{@boltconfig.tmpdir}\'" unless @boltconfig.tmpdir.nil?
    boltdir = %r{^/.*}.match?(@boltconfig.boltdir) ? @boltconfig.boltdir : "#{@env.root_path}/#{@boltconfig.boltdir}"
    command << "--boltdir \'#{boltdir}\'" unless @boltconfig.boltdir.nil?
    command << "--inventoryfile \'#{@inventory_path}\'" unless @inventory_path.nil?

    ## Configuration items
    command << "-n \'#{@boltconfig.node_list}\'" unless @boltconfig.node_list.nil?
    command << "--params \'#{@boltconfig.parameters.to_json}\'" unless @boltconfig.parameters.nil?

    ## Auth Settings
    command << "-u \'#{@boltconfig.user}\'" unless @boltconfig.user.nil?
    command << "-p \'#{@boltconfig.password}\'" unless @boltconfig.password.nil?
    command << "--run_as #{@boltconfig.run_as}" unless @boltconfig.run_as.nil?

    ## Connection Settings
    if windows?(@machine)
      ssl = (@boltconfig.ssl == true) ? "--ssl" : "--no-ssl"
      command << ssl unless @boltconfig.ssl.nil?
      ssl_verify = (@boltconfig.ssl_verify == true) ? "--ssl-verify" : "--no-ssl-verify"
      command << ssl_verify unless @boltconfig.ssl_verify.nil?
    else
      command << "--private-key \'#{@boltconfig.private_key}\'" unless @boltconfig.private_key.nil?
      host_key_check = (@boltconfig.host_key_check == true) ? "--host-key-check" : "--no-host-key-check"
      command << host_key_check unless @boltconfig.host_key_check.nil?
      command << "--sudo-password \'#{@boltconfig.sudo_password}\'" unless @boltconfig.sudo_password.nil?
    end

    ## Additional Options
    command << "--verbose" if @boltconfig.verbose
    command << "--debug" if @boltconfig.debug
    command << @boltconfig.args unless @boltconfig.args.nil?
    command.flatten.join(" ")
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
    errors << I18n.t('vagrant-bolt.config.bolt.errors.type_not_specified') if @boltconfig.type.nil?
    errors << I18n.t('vagrant-bolt.config.bolt.errors.no_task_or_plan') if @boltconfig.name.nil?
    { "Bolt" => errors }
  end
end
