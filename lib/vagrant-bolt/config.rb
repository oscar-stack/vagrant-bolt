# frozen_string_literal: true

class VagrantBolt::Config < Vagrant.plugin('2', :config)
  # @!attribute [rw] name
  #   @return [String] The name of task or plan to run
  attr_accessor :name

  # @!attribute [rw] type
  #   @return [Symbol] Task or Plan
  attr_accessor :type

  # @!attribute [rw] parameters
  #   @return [Hash] The paramater hash for the task or plan
  attr_accessor :parameters

  # @!attribute [rw] nodes
  # Note: The `nodelist` will override this setting.
  #   @return [Array<String, Symbol>, "ALL"] The nodes to run the task or plan on.
  #        Valid values are an array of machine names or the string "ALL".
  attr_accessor :nodes

  # @!attribute [rw] nodeexcludes
  # Note: The `nodelist` will override this setting.
  # Note: This will be merged with `nodes`, with `excludes` taking precidence
  #   @return [Array<String, Symbol>] The nodes to exclude from running this task or plan on.
  #        Valid values are an array of machine names.
  attr_accessor :nodeexcludes

  # @!attribute [rw] nodelist
  # This setting overrides `nodes` and needs to be in the `protocol://ipaddress:port` URI format
  #   @return [String] The bolt node list. This defaults to the currnet node.
  attr_accessor :nodelist

  # @!attribute [rw] username
  #   @return [String] The username to authenticate on the machine.
  attr_accessor :username

  # @!attribute [rw] password
  #   @return [String] The password to authenticate on the machine.
  attr_accessor :password

  # @!attribute [rw] sudopassword
  #   @return [String] The password to authenticate sudo on the machine.
  attr_accessor :sudopassword

  # @!attribute [rw] privatekey
  #   @return [String] The path of the privatekey to authenticate on the machine.
  attr_accessor :privatekey

  # @!attribute [rw] hostkeycheck
  #   @return [Boolean] If the connection should check the host key on the remote host (linux)
  attr_accessor :hostkeycheck

  # @!attribute [rw] ssl
  #   @return [Boolean] If the connection should use SSL on with WinRM (Windows)
  attr_accessor :ssl

  # @!attribute [rw] sslverify
  #   @return [Boolean] If the connection should verify SSL on with WinRM (Windows)
  attr_accessor :sslverify

  # @!attribute [rw] modulepath
  #   @return [String] The path to the modules. Defaults to `modules`.
  attr_accessor :modulepath

  # @!attribute [rw] tmpdir
  #   @return [String] The directory to upload and execute temporary files on the target
  attr_accessor :tmpdir

  # @!attribute [rw] verbose
  #   @return [Boolean] Shows verbose logging
  attr_accessor :verbose

  # @!attribute [rw] debug
  #   @return [Boolean] Shows debug logging
  attr_accessor :debug

  # @!attribute [rw] boltcommand
  #   @return [String] The full path to the bolt command. If not passed in, the default from PATH will be used.
  attr_accessor :boltcommand

  # @!attribute [rw] boltdir
  #   @return [String] The bolt working directory. Defaults to `.`
  attr_accessor :boltdir

  # @!attribute [rw] run_as
  #   @return [String] User to run as using privilege escalation.
  attr_accessor :run_as

  # @!attribute [rw] args
  #   @return [String] Additional arguments for the bolt command
  attr_accessor :args

  # @!attribute [rw] dependencies
  #   @return [Array<Symbol>] Machine names that should be online prior to running this task
  attr_accessor :dependencies

  def initialize
    @name             = UNSET_VALUE
    @type             = UNSET_VALUE
    @parameters       = UNSET_VALUE
    @nodes            = []
    @nodeexcludes     = []
    @nodelist         = UNSET_VALUE
    @username         = UNSET_VALUE
    @password         = UNSET_VALUE
    @privatekey       = UNSET_VALUE
    @sudopassword     = UNSET_VALUE
    @hostkeycheck     = UNSET_VALUE
    @ssl              = UNSET_VALUE
    @sslverify        = UNSET_VALUE
    @modulepath       = UNSET_VALUE
    @tmpdir           = UNSET_VALUE
    @verbose          = UNSET_VALUE
    @debug            = UNSET_VALUE
    @boltcommand      = UNSET_VALUE
    @boltdir          = UNSET_VALUE
    @run_as           = UNSET_VALUE
    @args             = UNSET_VALUE
    @dependencies     = []
  end

  def finalize!
    @name             = nil if @name == UNSET_VALUE
    @type             = nil if @type == UNSET_VALUE
    @parameters       = nil if @parameters == UNSET_VALUE
    @nodelist         = nil if @nodelist == UNSET_VALUE
    @username         = nil if @username == UNSET_VALUE
    @password         = nil if @password == UNSET_VALUE
    @sudopassword     = nil if @sudopassword == UNSET_VALUE
    @privatekey       = nil if @privatekey == UNSET_VALUE
    @hostkeycheck     = false if @hostkeycheck == UNSET_VALUE
    @ssl              = false if @ssl == UNSET_VALUE
    @sslverify        = false if @sslverify == UNSET_VALUE
    @modulepath       = 'modules' if @modulepath == UNSET_VALUE
    @tmpdir           = nil if @tmpdir == UNSET_VALUE
    @verbose          = false if @verbose == UNSET_VALUE
    @debug            = false if @debug == UNSET_VALUE
    @boltcommand      = 'bolt' if @boltcommand == UNSET_VALUE
    @boltdir          = '.' if @boltdir == UNSET_VALUE
    @run_as           = nil if @run_as == UNSET_VALUE
    @args             = nil if @args == UNSET_VALUE
  end

  def merge(other)
    super.tap do |result|
      new_dependencies = (dependencies + other.dependencies.dup).flatten.uniq
      result.instance_variable_set(:@dependencies, new_dependencies.to_a)
      new_nodeexcludes = (nodeexcludes + other.nodeexcludes.dup).flatten.uniq
      result.instance_variable_set(:@nodeexcludes, new_nodeexcludes.to_a)
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

    if @nodeexcludes.nil? || !(@nodeexcludes.is_a? Array)
      errors << I18n.t('vagrant-bolt.config.bolt.errors.invalid_data_type',
                       item: 'nodeexcludes',
                       type: 'array')
    end

    if @type.nil? && !@name.nil?
      errors << I18n.t('vagrant-bolt.config.bolt.errors.type_not_specified')
    elsif !@type.nil? && @name.nil?
      errors << I18n.t('vagrant-bolt.config.bolt.errors.no_task_or_plan')
    end

    { "Bolt" => errors }
  end
end
