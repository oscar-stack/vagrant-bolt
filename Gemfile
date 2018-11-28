# frozen_string_literal: true

source 'https://rubygems.org'
require 'rubygems/version'

vagrant_branch = ENV['TEST_VAGRANT_VERSION'] || 'v2.2.0'

group :plugins do
  gemspec
end

group :development do
  gem 'rake'
  gem 'redcarpet'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'yard', '~> 0.9.16'
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
  gem 'bolt'
end

eval_gemfile "#{__FILE__}.local" if File.exist? "#{__FILE__}.local"
