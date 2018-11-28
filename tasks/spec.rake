Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec) do |s|
    s.pattern = "spec/unit/**/*_spec.rb"
      s.rspec_opts = "--color"
end
