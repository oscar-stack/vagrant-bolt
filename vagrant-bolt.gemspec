$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'date'
require 'vagrant-bolt/version'

Gem::Specification.new do |gem|
  gem.name    = 'vagrant-bolt'
  gem.version = VagrantBolt::VERSION
  gem.date    = Date.today.to_s

  gem.summary     = 'Vagrant provisioning with Puppet Bolt'
  gem.description = <<-DESC
  Vagrant provisioning with Puppet Bolt
  DESC

  gem.authors  = ['Jarret Lavallee']
  gem.email    = ['jarret.lavallee@gmail.com']
  gem.homepage = 'https://github.com/oscar-stack/vagrant-bolt'

  gem.files        = %x{git ls-files -z}.split("\0")
  gem.require_path = 'lib'

  gem.license = 'Apache-2.0'
end
