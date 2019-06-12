# frozen_string_literal: true

require 'config_builder/model'
require_relative 'monkey_patches'

class VagrantBolt::ConfigBuilder::Provisioner < ConfigBuilder::Model::Provisioner::Base
  # @!attribute [rw] args
  # @return [String] Additional arguments for the bolt command
  def_model_attribute :args

  # @!attribute [rw] bolt_exe
  # @return [String] The full path to the bolt command. If not passed in, the default from PATH will be used.
  def_model_attribute :bolt_exe

  # @!attribute [rw] boltdir
  # @return [String] The bolt working directory. Defaults to `.`
  def_model_attribute :boltdir

  # @!attribute [rw] debug
  # @return [Boolean] Shows debug logging
  def_model_attribute :debug

  # @!attribute [rw] connect_timeout
  # @return [String] The ssh connection timeout (linux)
  def_model_attribute :connect_timeout

  # @!attribute [rw] host_key_check
  # @return [Boolean] If the connection should check the host key on the remote host (linux)
  def_model_attribute :host_key_check

  # @!attribute [rw] modulepath
  # @return [String] The path to the modules.
  def_model_attribute :modulepath

  # @!attribute [rw] name
  # @return [String] The name of task or plan to run
  def_model_attribute :name

  # @!attribute [rw] nodes
  # Note: The `node_list` will override this setting.
  # @return [Array<String, Symbol>, "ALL"] The nodes to run the task or plan on.
  # Valid values are an array of machine names or the string "ALL".
  def_model_attribute :nodes

  # @!attribute [rw] noop
  # @return [Boolean] If the command should be run with noop. Only valid with tasks and apply.
  def_model_attribute :noop

  # @!attribute [rw] excludes
  # Note: The `node_list` will override this setting.
  # Note: This will be merged with `nodes`, with `excludes` taking precidence.
  # @return [Array<String, Symbol>] The nodes to exclude from running this task or plan on.
  # Valid values are an array of machine names.
  def_model_attribute :excludes

  # @!attribute [rw] node_list
  # This setting overrides `nodes` and needs to be in the `protocol://ipaddress:port` URI format
  # @return [String] The bolt node list. This defaults to the currnet node.
  def_model_attribute :node_list

  # @!attribute [rw] params
  # @return [Hash] The paramater hash for the task or plan
  def_model_attribute :params

  # @!attribute [rw] command
  # @return [Symbol] Whether bolt should use a task or plan
  def_model_attribute :command

  # @!attribute [rw] user
  # @return [String] The user to authenticate on the machine.
  def_model_attribute :user

  # @!attribute [rw] password
  # @return [String] The password to authenticate on the machine.
  def_model_attribute :password

  # @!attribute [rw] port
  # @return [String] The port to connect to the machine.
  def_model_attribute :port

  # @!attribute [rw] private_key
  # @return [String] The path of the private_key to authenticate on the machine.
  def_model_attribute :private_key

  # @!attribute [rw] run_as
  # @return [String] User to run as using privilege escalation.
  def_model_attribute :run_as

  # @!attribute [rw] sudo_password
  # @return [String] The password to authenticate sudo on the machine.
  def_model_attribute :sudo_password

  # @!attribute [rw] ssl
  # @return [Boolean] If the connection should use SSL on with WinRM (Windows)
  def_model_attribute :ssl

  # @!attribute [rw] ssl_verify
  # @return [Boolean] If the connection should verify SSL on with WinRM (Windows)
  def_model_attribute :ssl_verify

  # @!attribute [rw] tmpdir
  # @return [String] The directory to upload and execute temporary files on the target
  def_model_attribute :tmpdir

  # @!attribute [rw] verbose
  # @return [Boolean] Shows verbose logging
  def_model_attribute :verbose

  ConfigBuilder::Model::Provisioner.register('bolt', self)
end
