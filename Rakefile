# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Dir.chdir(File.expand_path(__dir__))

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

task_dir = File.expand_path("tasks", __dir__)
Dir["#{task_dir}/**/*.rake"].each do |task_file|
  load task_file
end

task default: :spec
