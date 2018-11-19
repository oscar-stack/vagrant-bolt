# frozen_string_literal: true

require 'config_builder/model'

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
    bolt_type = options.delete(:bolt_type)
    name = options.delete(:name)
    proc do |config|
      config.trigger.send(trigger_type, trigger_commands) do |trigger|
        trigger.ruby do |env, machine|
          VagrantBolt.send(bolt_type, name, env, machine, **options)
        end
      end
    end
  end
end

class ConfigBuilder::Model::Root
  def_model_delegator :bolt_triggers
  def eval_bolt_triggers(config)
    triggers = attr(:bolt_triggers) || [] # rubocop:disable Style/Attr
    triggers.each do |trigger_config|
      f = VagrantBolt::ConfigBuilder::Triggers.new_from_hash(trigger_config)
      f.call(config)
    end
  end
end

# VM level requires overriding to_proc to allow access to the node config object
class ConfigBuilder::Model::VM
  def_model_delegator :bolt_triggers
  def to_proc
    proc do |config|
      vm_config = config.vm
      configure!(vm_config)
      eval_models(vm_config)
      eval_bolt_triggers_root(config)
    end
  end

  def eval_bolt_triggers(config)
    # noop
  end

  def eval_bolt_triggers_root(vm_root_config)
    # Configure the vm bolt object if the options exist
    triggers = attr(:bolt_triggers) || [] # rubocop:disable Style/Attr
    triggers.each do |config|
      f = VagrantBolt::ConfigBuilder::Triggers.new_from_hash(config)
      f.call(vm_root_config)
    end
  end
end
