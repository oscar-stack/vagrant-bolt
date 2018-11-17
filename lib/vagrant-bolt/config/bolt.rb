# frozen_string_literal: true

class VagrantBolt::Config::Bolt < VagrantBolt::Config::Global
  # @!attribute [rw] args
  #   @return [String] Additional arguments for the bolt command
  attr_accessor :args

  # @!attribute [rw] dependencies
  #   @return [Array<Symbol>] Machine names that should be online prior to running this task
  attr_accessor :dependencies

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

  def initialize
    super
    @args         = UNSET_VALUE
    @dependencies = []
    @name         = UNSET_VALUE
    @nodes        = []
    @excludes     = []
    @node_list    = UNSET_VALUE
    @parameters   = UNSET_VALUE
    @type         = UNSET_VALUE
  end

  def finalize!
    @bolt_command   = nil if @bolt_command == UNSET_VALUE
    @boltdir        = nil if @boltdir == UNSET_VALUE
    @host_key_check = nil if @host_key_check == UNSET_VALUE
    @modulepath     = nil if @modulepath == UNSET_VALUE
    @port           = nil if @port == UNSET_VALUE
    @password       = nil if @password == UNSET_VALUE
    @private_key    = nil if @private_key == UNSET_VALUE
    @run_as         = nil if @run_as == UNSET_VALUE
    @ssl            = nil if @ssl == UNSET_VALUE
    @ssl_verify     = nil if @ssl_verify == UNSET_VALUE
    @sudo_password  = nil if @sudo_password == UNSET_VALUE
    @tmpdir         = nil if @tmpdir == UNSET_VALUE
    @user           = nil if @user == UNSET_VALUE
    @verbose        = nil if @verbose == UNSET_VALUE
    @debug          = nil if @debug == UNSET_VALUE

    @args           = nil if @args == UNSET_VALUE
    @name           = nil if @name == UNSET_VALUE
    @node_list      = nil if @node_list == UNSET_VALUE
    @parameters     = nil if @parameters == UNSET_VALUE
    @type           = nil if @type == UNSET_VALUE
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
end
