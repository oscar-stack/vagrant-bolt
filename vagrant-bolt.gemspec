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

  gem.authors  = ['Jarret Lavallee', 'Charlie Sharpsteen']
  gem.email    = ['jarret@puppet.com']
  gem.homepage = 'https://github.com/jarretlavallee/vagrant-bolt'

# net-ssh has some version differences between bolt and vagrant
  # We require bolt to be installed in PATH
#  gem.add_dependency 'bolt', '~> 1.0'

  gem.files        = %x{git ls-files -z}.split("\0")
  gem.require_path = 'lib'

  gem.license = 'Apache-2.0'
end
