# frozen_string_literal: true

module VagrantBolt::ConfigBuilder::MonkeyPatches
end

class ConfigBuilder::Model::Root
  def_model_delegator :bolt
  def_model_delegator :bolt_triggers

  def eval_bolt(config)
    with_attr(:bolt) do |bolt_config|
      f = VagrantBolt::ConfigBuilder::Config.new_from_hash(bolt_config)
      f.call(config)
    end
  end

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
  def_model_delegator :bolt
  def_model_delegator :bolt_triggers

  def to_proc
    proc do |config|
      vm_config = config.vm
      configure!(vm_config)
      eval_models(vm_config)
      eval_bolt_root(config)
      eval_bolt_triggers_root(config)
    end
  end

  def eval_bolt(config)
    # noop
  end

  def eval_bolt_root(vm_root_config)
    # Configure the vm bolt object if the options exist
    with_attr(:bolt) do |bolt_config|
      f = VagrantBolt::ConfigBuilder::Config.new_from_hash(bolt_config)
      f.call(vm_root_config)
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
