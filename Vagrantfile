require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.ssh.insert_key = false
  config.bolt.run_as    = 'root'
  config.vm.define 'server' do |s|
    s.vm.provision :bolt do |bolt|
      bolt.task         = "facts::bash"
    end
  end
  config.vm.define 'server2' do |s|
    s.vm.provision :bolt do |bolt|
      bolt.task         = "facts::bash"
    end
    s.vm.provision :bolt do |bolt|
      bolt.task         = "service::linux"
      bolt.parameters   = {name: "cron", action: "restart"}
      bolt.nodes        = 'ALL'
    end
  end
end
