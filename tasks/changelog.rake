require 'github_changelog_generator/task'
require_relative '../lib/vagrant-bolt/version'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user ='oscar-stack'
  config.project = 'vagrant-bolt'
  config.future_release = VagrantBolt::VERSION
end
