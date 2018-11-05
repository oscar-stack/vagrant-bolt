# frozen_string_literal: true

module VagrantBolt
  require 'vagrant-bolt/version'
  require 'vagrant-bolt/plugin'
  require 'vagrant-bolt/runner'

  # Run a bolt task
  # @param [String] task The name of the bolt task to run
  # @param [Object] env The environment
  # @param [Object] machine The machine
  # @param [Hash] args A optional hash of bolt config overrides. No merging will be done with these overrides.
  # @example VagrantBolt.task('facts', env, machine, run_as: "root", parameters: {taskparam: "value"})
  def self.task(task, env, machine, **args)
    runner = VagrantBolt::Runner.new(env, machine)
    runner.run(:task, task, **args)
  end

  # Run a bolt plan
  # @param [String] plan The name of the bolt plan to run
  # @param [Object] env The environment
  # @param [Object] machine The machine
  # @param [Hash] args A optional hash of bolt config overrides. No merging will be done with these overrides.
  # @example VagrantBolt.plan('facts', env, machine, run_as: "root", parameters: {planparam: "value"})
  def self.plan(plan, env, machine, **args)
    runner = VagrantBolt::Runner.new(env, machine)
    runner.run(:plan, plan, **args)
  end

  def self.source_root
    @source_root ||= File.expand_path(__DIR__)
  end
end

I18n.load_path << File.expand_path('../templates/locales/en.yml', File.dirname(__FILE__))
