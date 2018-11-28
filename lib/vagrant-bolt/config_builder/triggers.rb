# frozen_string_literal: true

require 'config_builder/model'
require_relative 'monkey_patches'

class VagrantBolt::ConfigBuilder::Triggers < VagrantBolt::ConfigBuilder::Config
  # @!attribute [rw] trigger_type
  #   @return [Symbol] A symbol containing the the trigger action. Valid values are `:before` and `:after`
  def_model_attribute :trigger_type

  # @!attribute [rw] trigger_commands
  #   @return [Array<Symbol>] The commands that the trigger should run on. E.g. `[:up, :provision]`
  def_model_attribute :trigger_commands

  def to_proc
    options = @attrs.dup
    trigger_type = options.delete(:trigger_type)
    trigger_commands = options.delete(:trigger_commands)
    command = options.delete(:command)
    name = options.delete(:name)
    proc do |config|
      config.trigger.send(trigger_type, trigger_commands) do |trigger|
        trigger.ruby do |env, machine|
          VagrantBolt.send(command, name, env, machine, **options)
        end
      end
    end
  end
end
