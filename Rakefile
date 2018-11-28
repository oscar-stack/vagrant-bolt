# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Dir.chdir(File.expand_path(__dir__))

## Tasks
Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec) do |s|
  s.pattern = "spec/unit/**/*_spec.rb"
  s.rspec_opts = "--color"
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

task_dir = File.expand_path("spec/tasks", __dir__)
Dir["#{task_dir}/**/*.rake"].each do |task_file|
  load task_file
end

task default: :spec
