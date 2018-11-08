# frozen_string_literal: true

class VagrantBolt::Config < Vagrant.plugin('2', :config)
  # @!attribute [rw] args
  #   @return [String] Additional arguments for the bolt command
  attr_accessor :args

  # @!attribute [rw] bolt_command
  #   @return [String] The full path to the bolt command. If not passed in, the default from PATH will be used.
  attr_accessor :bolt_command

  # @!attribute [rw] boltdir
  #   @return [String] The bolt working directory. Defaults to `.`
  attr_accessor :boltdir

  # @!attribute [rw] debug
  #   @return [Boolean] Shows debug logging
  attr_accessor :debug

  # @!attribute [rw] dependencies
  #   @return [Array<Symbol>] Machine names that should be online prior to running this task
  attr_accessor :dependencies

  # @!attribute [rw] host_key_check
  #   @return [Boolean] If the connection should check the host key on the remote host (linux)
  attr_accessor :host_key_check

  # @!attribute [rw] modulepath
  #   @return [String] The path to the modules. Defaults to `modules`.
  attr_accessor :modulepath

  # @!attribute [rw] name
  #   @return [String] The name of task or plan to run
  attr_accessor :name

  # @!attribute [rw] nodes
  # Note: The `node_list` will override this setting.
  #   @return [Array<String, Symbol>, "ALL"] The nodes to run the task or plan on.
  #        Valid values are an array of machine names or the string "ALL".
  attr_accessor :nodes

  # @!attribute [rw] excludes
  # Note: The `node_list` will override this setting.
  # Note: This will be merged with `nodes`, with `excludes` taking precidence
  #   @return [Array<String, Symbol>] The nodes to exclude from running this task or plan on.
  #        Valid values are an array of machine names.
  attr_accessor :excludes

  # @!attribute [rw] node_list
  # This setting overrides `nodes` and needs to be in the `protocol://ipaddress:port` URI format
  #   @return [String] The bolt node list. This defaults to the currnet node.
  attr_accessor :node_list

  # @!attribute [rw] parameters
  #   @return [Hash] The paramater hash for the task or plan
  attr_accessor :parameters

  # @!attribute [rw] type
  #   @return [Symbol] Whether bolt should use a task or plan
  attr_accessor :type

  # @!attribute [rw] username
  #   @return [String] The username to authenticate on the machine.
  attr_accessor :username

  # @!attribute [rw] password
  #   @return [String] The password to authenticate on the machine.
  attr_accessor :password

  # @!attribute [rw] private_key
  #   @return [String] The path of the private_key to authenticate on the machine.
  attr_accessor :private_key

  # @!attribute [rw] run_as
  #   @return [String] User to run as using privilege escalation.
  attr_accessor :run_as

  # @!attribute [rw] sudo_password
  #   @return [String] The password to authenticate sudo on the machine.
  attr_accessor :sudo_password

  # @!attribute [rw] ssl
  #   @return [Boolean] If the connection should use SSL on with WinRM (Windows)
  attr_accessor :ssl

  # @!attribute [rw] ssl_verify
  #   @return [Boolean] If the connection should verify SSL on with WinRM (Windows)
  attr_accessor :ssl_verify

  # @!attribute [rw] tmpdir
  #   @return [String] The directory to upload and execute temporary files on the target
  attr_accessor :tmpdir

  # @!attribute [rw] verbose
  #   @return [Boolean] Shows verbose logging
  attr_accessor :verbose

  def initialize
    @args           = UNSET_VALUE
    @bolt_command   = UNSET_VALUE
    @boltdir        = UNSET_VALUE
    @debug          = UNSET_VALUE
    @dependencies   = []
    @host_key_check = UNSET_VALUE
    @modulepath     = UNSET_VALUE
    @name           = UNSET_VALUE
    @nodes          = []
    @excludes       = []
    @node_list      = UNSET_VALUE
    @parameters     = UNSET_VALUE
    @password       = UNSET_VALUE
    @private_key    = UNSET_VALUE
    @run_as         = UNSET_VALUE
    @ssl            = UNSET_VALUE
    @ssl_verify     = UNSET_VALUE
    @sudo_password  = UNSET_VALUE
    @tmpdir         = UNSET_VALUE
    @type           = UNSET_VALUE
    @username       = UNSET_VALUE
    @verbose        = UNSET_VALUE
  end

  def finalize!
    @args           = nil if @args == UNSET_VALUE
    @bolt_command   = 'bolt' if @bolt_command == UNSET_VALUE
    @boltdir        = '.' if @boltdir == UNSET_VALUE
    @debug          = false if @debug == UNSET_VALUE
    @host_key_check = false if @host_key_check == UNSET_VALUE
    @modulepath     = 'modules' if @modulepath == UNSET_VALUE
    @name           = nil if @name == UNSET_VALUE
    @node_list      = nil if @node_list == UNSET_VALUE
    @parameters     = nil if @parameters == UNSET_VALUE
    @password       = nil if @password == UNSET_VALUE
    @private_key    = nil if @private_key == UNSET_VALUE
    @run_as         = nil if @run_as == UNSET_VALUE
    @ssl            = false if @ssl == UNSET_VALUE
    @ssl_verify     = false if @ssl_verify == UNSET_VALUE
    @sudo_password  = nil if @sudo_password == UNSET_VALUE
    @tmpdir         = nil if @tmpdir == UNSET_VALUE
    @type           = nil if @type == UNSET_VALUE
    @username       = nil if @username == UNSET_VALUE
    @verbose        = false if @verbose == UNSET_VALUE
  end

  def merge(other)
    super.tap do |result|
      new_dependencies = (dependencies + other.dependencies.dup).flatten.uniq
      result.instance_variable_set(:@dependencies, new_dependencies.to_a)
      new_excludes = (excludes + other.excludes.dup).flatten.uniq
      result.instance_variable_set(:@excludes, new_excludes.to_a)
      unless nodes.to_s.casecmp("all").zero?
        new_nodes = (nodes + other.nodes.dup).flatten.uniq
        result.instance_variable_set(:@nodes, new_nodes.to_a)
      end
    end
  end

  def validate(_machine)
    errors = _detected_errors
    errors << I18n.t('vagrant-bolt.config.bolt.errors.invalid_type', type: @type.to_s) if !@type.nil? && !['task', 'plan'].include?(@type.to_s)

    if @dependencies.nil? || !(@dependencies.is_a? Array)
      errors << I18n.t('vagrant-bolt.config.bolt.errors.invalid_data_type',
                       item: 'dependencies',
                       type: 'array')
    end

    if @nodes.nil? || (!(@nodes.is_a? Array) && !@nodes.to_s.casecmp("all").zero?)
      errors << I18n.t('vagrant-bolt.config.bolt.errors.invalid_data_type',
                       item: 'nodes',
                       type: 'array')
    end

    if @excludes.nil? || !(@excludes.is_a? Array)
      errors << I18n.t('vagrant-bolt.config.bolt.errors.invalid_data_type',
                       item: 'excludes',
                       type: 'array')
    end

    if @type.nil? && !@name.nil?
      errors << I18n.t('vagrant-bolt.config.bolt.errors.type_not_specified')
    elsif !@type.nil? && @name.nil?
      errors << I18n.t('vagrant-bolt.config.bolt.errors.no_task_or_plan')
    end

    { "Bolt" => errors }
  end

  # Generate a bolt inventory config hash for this config
  # @return [Hash] A bolt inventory config hash containing the configured parameters
  def config_hash
    setting_map = {
      'ssh': [
        'user',
        'password',
        'run_as',
        'port',
        'private_key',
        'host_key_check',
        'sudo_password',
      ],
      'winrm': [
        'user',
        'password',
        'run_as',
        'ssl',
        'ssl_verify',
        'port',
      ],
    }
    configs = {}
    instance_variables_hash.each do |key, value|
      setting_map.each do |transport, settings|
        next unless settings.include?(key)

        configs[transport.to_s] ||= {}
        configs[transport.to_s][key.tr('_', '-')] = value unless value.nil?
      end
    end
    configs
  end
end
