require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.define 'server' do |s|
    s.vm.provision :bolt do |config|
      config.task             = "facts::bash"
    end
  end
end
