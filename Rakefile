require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Dir.chdir(File.expand_path("../", __FILE__))


## Tasks
Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new(:rubocop) do |t|
      t.options = ['--display-cop-names']
end

task :default => :spec
