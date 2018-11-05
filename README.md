vagrant-bolt
============

Manage [vagrant](https://www.vagrantup.com) machines with [Puppet Bolt](https://puppet.com/docs/bolt).


Synopsis
--------

**vagrant-bolt** is a [vagrant](https://www.vagrantup.com) plugin enabling the use of [Puppet Bolt](https://puppet.com/docs/bolt) as a provisioner. Bolt commands can be configured in the Vagrantfile to be run as a provisioner or integrated with triggers. Bolt tasks and Plans can help automate configuration and orchestrate changes across machines.

Usage
-----

The vagrant-bolt plugin can be used either as a provisioner or in a ruby block trigger. Both methods can use the bolt config object to inherit configuration options. The provisioner and trigger can provision bolt tasks and plans using the locally installed bolt command and modules.

### Ruby Triggers
Ruby triggers, implemented in Vagrant 2.2.0, allow for specifying a block of ruby code as the trigger. See the [trigger documentation](https://www.vagrantup.com/docs/triggers/) for more information around triggers. Below is an example Vagrantfile to add a bolt ruby trigger at the root.

~~~ruby
require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.ssh.insert_key = false

  # Using a global bolt trigger for a plan
  # This will fire on all machines after :up
  config.trigger.after :up do |trigger|
    trigger.name = "Bolt \"facts\" after :up"
    trigger.ruby do |env, machine|
      VagrantBolt.plan("facts", env, machine)
    end
  end
end
~~~

Both tasks and plans can be configured using the appropiate methods. `VagrantBolt.task` for tasks and `VagrantBolt.plan` for plans.

### Provisioner
vagrant-bolt also provides a traditional provisioner which can be added to a machine. Below is an example Vagrantfile which runs a bolt task on a machine.

~~~ruby
require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.ssh.insert_key = false

  config.vm.define 'server' do |node|
    node.vm.provision :bolt do |bolt|
      bolt.type         = :task
      bolt.name         = "service::linux"
      bolt.parameters   = { name: "cron", action: "restart" }
      bolt.run_as       = "root"
    end
  end
end
~~~

Configuration Options
---------------------
Configuring the vagrant-bolt plugin can be done through the provisioner config and in the trigger method. Each way has different capabilities, so they may fit different use cases.

### Config Objects
The plugin provides a `bolt` config object at the `root`, `vm`, and `provisioner` levels. Each level inherits from the parent and are all merged into the final configuration. An example Vagrantfile has all three levels included.

~~~ruby
require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.ssh.insert_key = false
  # Root level config will be applied to all bolt provisioners and triggers
  config.bolt.verbose   = true

  config.vm.define 'server' do |node|
    # VM level config will be applied to all bolt provisioners and triggers for the VM
    node.bolt.run_as    = "root"
    node.vm.provision :bolt do |bolt|
      # Provisioner level config is only applied to this provisioner
      bolt.type         = :task
      bolt.name         = "facts"
    end
  end
end
~~~

The configuration above would result in the `facts` task being run on the VM with `run_as = root`, and `verbose = true`. Configuration items defined in a more specific scope will override the least specific scope, and arrays will be deep merged.

The config object applies to the triggers as well. The example Vagrantfile will result in the same options being applied.

~~~ruby
require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.ssh.insert_key = false
  # Root level config will be applied to all bolt provisioners and triggers
  config.bolt.verbose   = true

  config.vm.define 'server' do |node|
    # VM level config will be applied to all bolt provisioners and triggers for the VM
    node.bolt.run_as    = "root"
    node.trigger.after :up do |trigger|
      trigger.name = "Bolt \"facts\" after :up"
      trigger.ruby do |env, machine|
        VagrantBolt.task("facts", env, machine)
      end
    end
  end
end
~~~

### Trigger options
In addition to the config objects, the trigger method takes options for additional configuration. Unlike the config objects, the options specified in the method strictly override the config objects and are not merged. Below is an example of using the config objects with method overrides.

~~~ruby
require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.ssh.insert_key = false
  # Root level config will be applied to all bolt provisioners and triggers
  config.bolt.verbose   = true

  config.vm.define 'server' do |node|
    # VM level config will be applied to all bolt provisioners and triggers for the VM
    node.bolt.run_as = 'root'
    node.trigger.after :up do |trigger|
      trigger.name = "Bolt \"facts\" after up"
      trigger.ruby do |env, machine|
        # Specify additional **options for the task
        VagrantBolt.task("facts", env, machine, hostkeycheck: false, verbose: false)
      end
    end
  end
end
~~~

The configuration above would result in the `facts` task being run on the VM with `run_as = root`, `hostkeycheck = false`, and `verbose = false`. The `verbose` defined in the method will override the root level `verbose` option.

#### Trigger Methods
The methods for a bolt command in a trigger allow for a task and a plan. Both methods take the same arguments. 

* **VagrantBolt.task**
  * Description: Run a bolt task based on the config and arguments
  * Parameters:
    * Required: `name` A string containing the name of the task to run
    * Required: `env` The env object
    * Required: `machine` The machine object
    * Optional: `**args` A hash of [Plugin Settings](#plugin-settings) which override any previous config
* **VagrantBolt.plan**
  * Description: Run a bolt plan based on the config and arguments
  * Parameters:
    * Required: `name` A string containing the name of the plan to run
    * Required: `env` The env object
    * Required: `machine` The machine object
    * Optional: `**args` A hash of [Plugin Settings](#plugin-settings) which override any previous config

Example of the arguments can be seen below. 

Run the `facts` task using a specific username and password.

~~~ruby
VagrantBolt.task('facts', env, machine, username: 'ubuntu', password: 'testpassword')
~~~

Run the `facts` plan on `server1` and `server2`.

~~~ruby
VagrantBolt.plan('facts', env, machine, nodes: [:server1, :server2])
~~~

Run the `service::linux` task as `root` to restart `cron` with a specific path to the bolt executable. This configuration specifies parameters for the `service::linux` task.

~~~ruby
VagrantBolt.task('service::linux',
                 env,
                 machine,
                 run_as: 'root',
                 boltcommand: '/usr/local/bin/bolt',
                 parameters:  { name: "cron", action: "restart" },
                 )
~~~

Plugin Settings
---------------
The settings available in the triggers and the provisioner are the same.

**Required Settings**
* `type`
  * Description: A string containing plan or task to determine which will be used
  * Valid Values: `task` and `plan`
* `name`
  * Description: A string containing name of the task or plan to run

**Optional Settings**
* `boltcommand`
  * Description: A string containing the full path to the bolt executable
  * Default: `bolt`
* `boltdir`
  * Description: A string containing the bolt working directory
  * Default: `.`
* `nodelist`
  * Description: A string containing bolt node list in URI format
    * This will override `nodes` and `nodeexcludes`
  * Default: `%{protocol}://%{ssh_ip}:%{ssh_port}`
* `nodes`
  * Description: An array of machine names to run the task or plan on
    * The `nodelist` will override this setting.
    * A special `ALL` string can be used instead of an array to use all active machines in the environment
  * Valid Values: An array of machine symbols or the string "ALL"
  * Default: `[]`
* `nodeexcludes`
  * Description: An array of machine names to not run the task on
    * The `nodelist` will override this setting.
    * This setting will take precidence over `nodes`
  * Valid Values: An array of machine symbols
  * Default: `[]`
* `dependencies`
  * Description: An array of machine names that should be online prior to running the task or plan
    * An exception is raised when the machines are not available
  * Default: `[]`
* `parameters`
  * Description: A hash of the parameters for the bolt task or plan
* `password`
  * Description: A string containing the password bolt will use to connect to the machine
* `username`
  * Description: A string containing the username bolt will use to connect to the machine
  * Default: The username vagrant uses to connect to the machine
* `sudopassword`
  * Description: A string containing the password bolt will use to escalate privileges on the machine
* `hostkeycheck`
  * Description: A boolean which controls if the connection should check the host key on the remote host (linux)
  * Default: `false`
* `privatekey`
  * Description: A string containing the path to a ssh private key that bolt will use to connect to the machine
  * Default: The key vagrant uses to connect to the machine
* `ssl`
  * Description: A boolean which controls if the connection should use SSL on with WinRM (Windows)
  * Default: `false`
* `sslverify`
  * Description: A boolean which controls if the connection should verify SSL on with WinRM (Windows)
  * Default: `false`
* `modulepath`
  * Description: A string containing the path to bolt modules
  * Default: `modules`
* `tmpdir`
  * Description: A string containing the directory to upload and execute temporary files on the target
* `verbose`
  * Description: A boolean which controls if bolt will output verbose logs
  * Default: `false`
* `debug`
  * Description: A boolean which controls if bolt will output debug logs
  * Default: `false`
* `run_as`
  * Description: A string containing the user to run commands as on the machine
* `args`
  * Description: A string containing additional arguments to be passed into the bolt command



Installation
------------


Requirements
------------
* Vagrant 2.2.0+ is required for this plugin. 
* Bolt 1.x+ needs to be installed on the platform machine.
* Ruby 2.3+
