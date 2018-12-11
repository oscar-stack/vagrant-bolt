# frozen_string_literal: true

require 'config_builder/model'

module VagrantBolt::ConfigBuilder
  # Enable config builder loading of this plugin

  require_relative 'config_builder/provisioner'
  require_relative 'config_builder/config'
  require_relative 'config_builder/triggers'
end
