require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "alpine/alpine64"
  config.bolt.run_as = 'root'

  # Using a global bolt trigger for a plan
  # This will fire on all machines after :up
  config.trigger.after :up do |trigger|
    trigger.name = "Bolt \"facts::bash\" after :up"
    trigger.ruby do |env, machine|
      VagrantBolt.plan("facts", env, machine)
    end
  end

  ## Server
  config.vm.define 'server' do |node|
    # Machine level bolt configs
    node.bolt.run_as = 'vagrant'
    # Trigger bolt using a trigger
    node.trigger.after :provision do |trigger|
      trigger.name = "Bolt \"facts::bash\" after provision"
      trigger.ruby do |env, machine|
        # Sending additional config for the task
        VagrantBolt.task("facts::bash", env, machine, host_key_check: false, verbose: true)
      end
    end
  end

  ## Server2
  config.vm.define 'server2' do |node|
    # Using the Bolt provisioner instead of a trigger
    node.vm.provision :bolt do |bolt|
      bolt.command = :task
      bolt.name    = "service::linux"
      bolt.params  = { name: "chronyd", action: "restart" }
      bolt.nodes   = 'ALL'
      bolt.run_as  = "root"
    end
    # Using a command before the machine is destroyed
    node.trigger.before :destroy do |trigger|
      trigger.name = "Bolt \"hostname\" after up"
      trigger.ruby do |env, machine|
        VagrantBolt.command("hostname", env, machine)
      end
    end
  end
end
