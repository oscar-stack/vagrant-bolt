# frozen_string_literal: true

source 'https://rubygems.org'
require 'rubygems/version'

vagrant_branch = ENV['TEST_VAGRANT_VERSION'] || 'v2.2.2'

group :plugins do
  gemspec
end

group :development do
  gem 'rake'
  gem 'redcarpet'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'yard', '~> 0.9.16'
  gem 'github_changelog_generator'
end

group :test do
  if %r{head}i.match?(vagrant_branch)
    gem 'vagrant', git: 'https://github.com/hashicorp/vagrant.git',
                   branch: 'master'
  else
    gem 'vagrant', git: 'https://github.com/hashicorp/vagrant.git',
                   tag: vagrant_branch
  end

  gem 'vagrant-spec', git: 'https://github.com/hashicorp/vagrant-spec.git'
end

group :system_tests do
  gem 'bolt', ">=1.5.0"
end


eval_gemfile "#{__FILE__}.local" if File.exist? "#{__FILE__}.local"
