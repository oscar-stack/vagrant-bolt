# frozen_string_literal: true

require 'pathname'

module VagrantBolt::Util
  module Config
    # Config Utility Functions

    # Merge config objects overriding Nil and UNSET_VALUE
    # Since the configs have been finalized they will have `nil` values
    # Arrays will be merged and override parent non arrays
    # instead of UNSET_VALUE
    # @param local [Object] The local config object
    # @param other [Object] The other config object
    # @return [Object] A merged result with local overriding other
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

    # Convert a path to the absolute path if it is relative
    # @param path [String] The path to convert
    # @param root_path [Object] The root path to append
    # @return [String] The absolute path or nil if path is nil
    def self.full_path(path, root_path)
      return path if path.nil? || root_path.nil?

      (Pathname.new path).absolute? ? path : File.expand_path(path, root_path)
    end

    # Convert a path to the relative path from the current directory
    # @param path [String] The path to convert
    # @param root_path [Object] The root path to append
    # @return [String] The relative path or nil if path is nil
    def self.relative_path(path, root_path)
      return path if path.nil?

      absolute_path = Pathname.new full_path(path, root_path)
      absolute_path.relative_path_from(Pathname.getwd).to_s
    end
  end
end
