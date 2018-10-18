source 'https://rubygems.org'
require 'rubygems/version'

vagrant_branch = ENV['TEST_VAGRANT_VERSION'] || 'v2.2.0'

group :plugins do
  gemspec
end

group :development do
  gem 'yard', '~> 0.9.16'
  gem 'redcarpet'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'rake'
end

group :test do
  case vagrant_branch
  when /head/i
    gem 'vagrant', :git => 'https://github.com/hashicorp/vagrant.git',
      :branch => 'master'
  else
    gem 'vagrant', :git => 'https://github.com/hashicorp/vagrant.git',
      :tag => vagrant_branch
  end

  gem 'vagrant-spec', :git => 'https://github.com/hashicorp/vagrant-spec.git'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"
