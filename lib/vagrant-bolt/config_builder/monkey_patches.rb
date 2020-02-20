# frozen_string_literal: true

# VM level requires overriding to_proc to allow access to the node config object
# @!visibility private
module VagrantBolt::ConfigBuilder::MonkeyPatches
  def to_proc
    proc do |config|
      super.call(config)
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
    triggers = attr(:bolt_triggers) || []
    triggers.each do |config|
      f = VagrantBolt::ConfigBuilder::Triggers.new_from_hash(config)
      f.call(vm_root_config)
    end
  end
end

class ConfigBuilder::Model::VM
  def_model_delegator :bolt
  def_model_delegator :bolt_triggers
end

ConfigBuilder::Model::VM.prepend(VagrantBolt::ConfigBuilder::MonkeyPatches)

# Allow for the role filter to handle bolt configs and bolt_triggers
# @!visibility private
module VagrantBolt::ConfigBuilder::MonkeyPatches::FilterRoles
  def merge_nodes!(left, right)
    super.tap do |result|
      array_keys = ['bolt_triggers']
      array_keys.each do |key|
        next unless right.key?(key)

        result[key] ||= []
        result[key].unshift(*right[key])
      end

      hash_keys = ['bolt']
      hash_keys.each do |key|
        next unless right.key?(key)

        result[key] ||= {}
        result[key] = right[key].merge(result[key])
      end
    end
  end
end

ConfigBuilder::Filter::Roles.prepend(VagrantBolt::ConfigBuilder::MonkeyPatches::FilterRoles)
