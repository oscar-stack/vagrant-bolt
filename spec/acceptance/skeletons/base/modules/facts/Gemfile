# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

def location_for(place_or_version, fake_version = nil)
  if place_or_version =~ /\A(git[:@][^#]*)#(.*)/
    [fake_version, { git: Regexp.last_match(1), branch: Regexp.last_match(2), require: false }].compact
  elsif place_or_version =~ %r{\Afile:\/\/(.*)}
    ['>= 0', { path: File.expand_path(Regexp.last_match(1)), require: false }]
  else
    [place_or_version, { require: false }]
  end
end

ruby_version_segments = Gem::Version.new(RUBY_VERSION.dup).segments
minor_version = ruby_version_segments[0..1].join('.')

group :development do
  if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.1.0')
    gem "fast_gettext", '1.1.0', require: false
  elsif Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
    gem "fast_gettext", require: false
  end
  if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
    gem "json_pure", '<= 2.0.1', require: false
  end
  if Gem::Version.new(RUBY_VERSION.dup) == Gem::Version.new('2.1.9')
    gem "json", '= 1.8.1', require: false
  end
  if Gem::Version.new(RUBY_VERSION.dup) == Gem::Version.new('2.4.4')
    gem "json", '<= 2.0.4', require: false
  end
  gem "puppet-module-posix-default-r#{minor_version}",
      require: false, platforms: [:ruby]
  gem "puppet-module-posix-dev-r#{minor_version}",
      require: false, platforms: [:ruby]
  gem "puppet-module-win-default-r#{minor_version}",
      require: false, platforms: %i[mswin mingw x64_mingw]
  gem "puppet-module-win-dev-r#{minor_version}",
      require: false, platforms: %i[mswin mingw x64_mingw]
  gem "puppet-blacksmith", '~> 3.4',
      require: false, platforms: [:ruby]
end

group :system_tests do
  gem "puppet-module-posix-system-r#{minor_version}",
      require: false, platforms: [:ruby]
  gem "puppet-module-win-system-r#{minor_version}",
      require: false, platforms: %i[mswin mingw x64_mingw]
  gem "beaker", *location_for(ENV['BEAKER_VERSION'] || '~> 3.13')
  gem "beaker-abs", *location_for(ENV['BEAKER_ABS_VERSION'] || '~> 0.1')
  gem "beaker-hostgenerator"
  gem "beaker-pe",
      require: false
  gem "beaker-rspec"
end

# Temporarily pin to Puppet 6. 6.0.1 introduces a change in behavior that
# will require a newer release of Bolt for bolt_spec to work.
puppet_version = ENV['PUPPET_GEM_VERSION'] || '= 6.0.0'
facter_version = ENV['FACTER_GEM_VERSION']
hiera_version = ENV['HIERA_GEM_VERSION']

gems = {}

# If facter or hiera versions have been specified via the environment
# variables

gems['facter'] = location_for(facter_version) if facter_version
gems['hiera'] = location_for(hiera_version) if hiera_version
gems['puppet'] = location_for(puppet_version) if puppet_version
gem 'bolt', '~> 0.23.0'

if Gem.win_platform? && puppet_version =~ %r{^(file:///|git://)}
  # If we're using a Puppet gem on Windows which handles its own win32-xxx gem
  # dependencies (>= 3.5.0), set the maximum versions (see PUP-6445).
  gems['win32-dir'] =      ['<= 0.4.9', require: false]
  gems['win32-eventlog'] = ['<= 0.6.5', require: false]
  gems['win32-process'] =  ['<= 0.7.5', require: false]
  gems['win32-security'] = ['<= 0.2.5', require: false]
  gems['win32-service'] =  ['0.8.8', require: false]
end

gems.each do |gem_name, gem_params|
  gem gem_name, *gem_params
end

# Evaluate Gemfile.local and ~/.gemfile if they exist
extra_gemfiles = ["#{__FILE__}.local", File.join(Dir.home, '.gemfile')]

extra_gemfiles.each do |gemfile|
  # rubocop:disable Security/Eval
  if File.file?(gemfile) && File.readable?(gemfile)
    eval(File.read(gemfile), binding)
  end
  # rubocop:enable Security/Eval
end
# vim: syntax=ruby
