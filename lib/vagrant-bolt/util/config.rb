# frozen_string_literal: true

module VagrantBolt::Util
  module Config
    # Config Utility Functions

    # Merge config objects overriding Nil and UNSET_VALUE
    # Since the configs have been finalized they will have `nil` values
    # Arrays will be merged and override parent non arrays
    # instead of UNSET_VALUE
    # @param [Object] local The local config object
    # @param [Object] other The other config object
    # @return [Object] a merged result with local overriding other
    def self.merge_config(local, other)
      result = local.class.new
      [other, local].each do |obj|
        obj.instance_variables.each do |key|
          value = obj.instance_variable_get(key)
          if value.is_a? Array
            res_value = result.instance_variable_get(key)
            value = (value + res_value).uniq if res_value.is_a? Array
          elsif value.is_a? Hash
            res_value = result.instance_variable_get(key)
            value = res_value.merge(value) if res_value.is_a? Hash
          end
          result.instance_variable_set(key, value) if value != Vagrant::Plugin::V2::Config::UNSET_VALUE && !value.nil?
        end
      end
      result.finalize!
      result
    end
  end
end
