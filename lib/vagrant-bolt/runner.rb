require 'vagrant-bolt/util'

class VagrantBolt::Runner

  def initialize(env, machine, boltconfig = nil)
    @env = env
    @machine = machine
    @boltconfig = boltconfig.nil? ? machine.config.bolt : boltconfig
  end

  # Run a bolt task or plan
  # @param [Symbol|String] type The type of bolt to run; task or plan
  # @param [String] name The name of the bolt task or plan to run
  # @param [Array[Hash], nil] args A optional hash of bolt config overrides; {run_as: "vagrant"}
  def run(type, name, **args)
    @boltconfig = setup_overrides(type, name, **args)
    validate
    run_bolt
  end

  private

  include VagrantBolt::Util

  # Set up config overrides
  # @param [Symbol|String] type The type of bolt to run; task or plan
  # @param [String] name The name of the bolt task or plan to run
  # @param [Array[Hash], nil] args A optional hash of bolt config overrides; {run_as: "vagrant"}
  # @return [Object] Bolt config with ssh info populated
  def setup_overrides(type, name, **args)
    config = @boltconfig.dup
    config.type = type
    config.name = name
    # Add any additional arguments to the config object
    config.set_options(args) unless args.nil?

    # Pupulate ssh_info
    config.nodes = all_node_list(@env) if config.nodes.to_s.downcase == "all"
    ssh_info = @machine.ssh_info
    raise Vagrant::Errors::SSHNotReady if ssh_info.nil?
    config.nodes ||= "#{ssh_info[:host]}:#{ssh_info[:port]}"
    config.username ||= ssh_info[:username]
    config.privatekey ||= ssh_info[:private_key_path][0]
    config.hostkeycheck ||= ssh_info[:verify_host_key]
    return config
  end

  # Run bolt locally with an execute
  def run_bolt
    command = create_command
    @machine.ui.info(
      I18n.t('vagrant-bolt.provisioner.bolt.info.running_bolt',
        :command => command,
        ))

    result = Vagrant::Util::Subprocess.execute(
        'bash',
        '-c',
        command,
        :notify => [:stdout, :stderr],
        :env => {PATH: ENV["VAGRANT_OLD_ENV_PATH"]},
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
    #TODO: add all of the bolt the options and account for Windows Guests
    command = []
    command << @boltconfig.boltcommand
    command << "#{@boltconfig.type.to_s} run #{@boltconfig.name}"
    command << "-u #{@boltconfig.username}" unless @boltconfig.username.nil?

    # Windows and Linux specific items (This is for the agent side, so it doesn't fully make sense)
    if Vagrant::Util::Platform.windows?
      ssl = (@boltconfig.ssl == true) ? "--ssl" : "--no-ssl"
      command << ssl
      sslverify = (@boltconfig.sslverify == true) ? "--ssl-verify" : "--no-ssl-verify"
      command << sslverify
    else
      command << "--private-key #{@boltconfig.privatekey}" unless @boltconfig.privatekey.nil?
      host_key_check = (@boltconfig.hostkeycheck == true) ? "--host-key-check" : "--no-host-key-check"
      command << host_key_check
      command << "--sudo-password \'#{@boltconfig.sudopassword}\'" unless @boltconfig.sudopassword.nil?

    end

    command << "--run_as #{@boltconfig.run_as}" unless @boltconfig.run_as.nil?
    command << "--modulepath #{@boltconfig.modulepath}"
    command << "-n #{@boltconfig.nodes}"
    command << "--params \'#{@boltconfig.parameters.to_json}\'" unless @boltconfig.parameters.nil?
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

    if errors && !errors.empty?
      raise Vagrant::Errors::ConfigInvalid,
        errors: Vagrant::Util::TemplateRenderer.render(
          "config/validation_failed",
          errors: errors)
    end

  end

  # Validate a bolt config object for logical errors
  def validate_config
    errors = []
      errors << I18n.t('vagrant-bolt.config.bolt.errors.type_not_specified') if @boltconfig.type.nil?
      errors << I18n.t('vagrant-bolt.config.bolt.errors.no_task_or_plan') if @boltconfig.name.nil?
    {"Bolt" => errors }
  end
end
