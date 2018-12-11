# frozen_string_literal: true

module VagrantBolt
  require 'vagrant-bolt/version'
  require 'vagrant-bolt/plugin'
  require 'vagrant-bolt/runner'

  # Runs a bolt task with the specified parameters
  #
  # @param [String] task The name of the bolt task to run
  # @param [Object] env The environment
  # @param [Object] machine The machine
  # @param [Hash] args A optional hash of bolt config overrides. No merging will be done with these overrides.
  # @return [nil]
  # @example
  #   VagrantBolt.task('facts', env, machine, run_as: "root", params: {taskparam: "value"})
  def self.task(task, env, machine, **args)
    runner = VagrantBolt::Runner.new(env, machine)
    runner.run(:task, task, **args)
  end

  # Run a bolt plan with the specified parameters
  #
  # @param [String] plan The name of the bolt plan to run
  # @param [Object] env The environment
  # @param [Object] machine The machine
  # @param [Hash] args A optional hash of bolt config overrides. No merging will be done with these overrides.
  # @return [nil]
  # @example
  #    VagrantBolt.plan('facts', env, machine, run_as: "root", params: {planparam: "value"})
  def self.plan(plan, env, machine, **args)
    runner = VagrantBolt::Runner.new(env, machine)
    runner.run(:plan, plan, **args)
  end

  # Run a bolt command with the specified parameters
  #
  # @param [String] command The command to run
  # @param [Object] env The environment
  # @param [Object] machine The machine
  # @param [Hash] args A optional hash of bolt config overrides. No merging will be done with these overrides.
  # @return [nil]
  # @example
  #   VagrantBolt.command('/bin/echo "test"', env, machine, run_as: "root")
  def self.command(command, env, machine, **args)
    runner = VagrantBolt::Runner.new(env, machine)
    runner.run(:command, command, **args)
  end

  # Return the root directory of the source
  # @return [String] the source root path
  def self.source_root
    @source_root ||= File.expand_path(__DIR__)
  end
end

I18n.load_path << File.expand_path('../templates/locales/en.yml', File.dirname(__FILE__))
