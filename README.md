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

Tasks, plans, and commands can be configured using the appropiate methods. `VagrantBolt.task` for tasks, `VagrantBolt.plan` for plans, and `VagrantBolt.command` for commands.

### Provisioner

vagrant-bolt also provides a traditional provisioner which can be added to a machine. Below is an example Vagrantfile which runs a bolt task on a machine.

~~~ruby
require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.define 'server' do |node|
    node.vm.provision :bolt do |bolt|
      bolt.command      = :task
      bolt.name         = "service::linux"
      bolt.params       = { name: "cron", action: "restart" }
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
  # Root level config will be applied to all bolt provisioners and triggers
  config.bolt.verbose   = true

  config.vm.define 'server' do |node|
    # VM level config will be applied to all bolt provisioners and triggers for the VM
    node.bolt.run_as    = "root"
    node.vm.provision :bolt do |bolt|
      # Provisioner level config is only applied to this provisioner
      bolt.command      = :task
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
  # Root level config will be applied to all bolt provisioners and triggers
  config.bolt.verbose   = true

  config.vm.define 'server' do |node|
    # VM level config will be applied to all bolt provisioners and triggers for the VM
    node.bolt.run_as = 'root'
    node.trigger.after :up do |trigger|
      trigger.name = "Bolt \"facts\" after up"
      trigger.ruby do |env, machine|
        # Specify additional **options for the task
        VagrantBolt.task(
          "facts",
          env,
          machine,
          host_key_check: false,
          verbose: false,
        )
      end
    end
  end
end
~~~

The configuration above would result in the `facts` task being run on the VM with `run_as = root`, `host_key_check = false`, and `verbose = false`. The `verbose` defined in the method will override the root level `verbose` option.

#### Trigger Methods

The methods for a bolt command in a trigger allow for a task, plan, or command. All methods take the same arguments.

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
* **VagrantBolt.command**
  * Description: Run a bolt command based on the config and arguments
  * Parameters:
    * Required: `name` A string containing the command to run
    * Required: `env` The env object
    * Required: `machine` The machine object
    * Optional: `**args` A hash of [Plugin Settings](#plugin-settings) which override any previous config

An example of the arguments can be seen below.

Run the `facts` task using a specific user and password.

~~~ruby
VagrantBolt.task('facts', env, machine, user: 'ubuntu', password: 'testpassword')
~~~

Run the `facts` plan on `server1` and `server2`.

~~~ruby
VagrantBolt.plan('facts', env, machine, targets: [:server1, :server2])
~~~

Run the `hostname` command on all targets.

~~~ruby
VagrantBolt.command('/bin/hostname', env, machine, targets: 'all')
~~~

Run the `service::linux` task as `root` to restart `cron` with a specific path to the bolt executable. This configuration specifies params for the `service::linux` task.

~~~ruby
VagrantBolt.task(
  'service::linux',
  env,
  machine,
  run_as: 'root',
  bolt_exe: '/opt/puppetlabs/bin/bolt',
  params: { name: "cron", action: "restart" },
)
~~~

Plugin Settings
---------------

The settings available in the triggers and the provisioner are the same.

**Required Settings**

* `command`
  * Description: A string containing plan or task to determine which will be used
  * Valid Values: `task`, `plan`, and `command`
* `name`
  * Description: A string containing name of the task, plan, or command to run

**Optional Settings**

* `bolt_exe`
  * Description: A string containing the full path to the bolt executable
  * Default: `/opt/puppetlabs/bin/bolt` if it exists, else the first `bolt` in the PATH
* `boltdir`
  * Description: A string containing the bolt working directory
  * Default: The vagrant root
* `target_list`
  * Description: A string containing bolt target list in URI format
    * This will override `targets` and `excludes`
  * Default: `%{protocol}://%{ssh_ip}:%{ssh_port}` if `targets` is not specified
* `targets`
  * Description: An array of machine names to run the task or plan on
    * The `target_list` will override this setting.
    * A special `ALL` string can be used instead of an array to use all active machines in the environment
  * Valid Values: An array of machine symbols or the string "ALL"
  * Default: `[]`
* `excludes`
  * Description: An array of machine names to not run the task on
    * The `target_list` will override this setting.
    * This setting will take precidence over `targets`
  * Valid Values: An array of machine symbols
  * Default: `[]`
* `params`
  * Description: A hash of the params for the bolt task or plan
* `password`
  * Description: A string containing the password bolt will use to connect to the machine
* `user`
  * Description: A string containing the user bolt will use to connect to the machine
  * Default: The user vagrant uses to connect to the machine
* `port`
  * Description: A string containing the port bolt will use to connect to the machine
  * Default: The port that vagrant uses to connect to the machine
* `sudo_password`
  * Description: A string containing the password bolt will use to escalate privileges on the machine
* `connect_timeout`
  * Description: A string which controls if the connection timeout for ssh (linux)
* `host_key_check`
  * Description: A boolean which controls if the connection should check the host key on the remote host (linux)
  * Default: `false`
* `private_key`
  * Description: A string containing the path to a ssh private key that bolt will use to connect to the machine
  * Default: The key vagrant uses to connect to the machine
* `ssl`
  * Description: A boolean which controls if the connection should use SSL on with WinRM (Windows)
* `ssl_verify`
  * Description: A boolean which controls if the connection should verify SSL on with WinRM (Windows)
* `machine_alias`
  * Description: A string to use as the machine's alias in the bolt inventory file. Defaults to nil unless `machine_name` is configured in which case it defaults to the machine name.
* `machine_name`
  * Description: A string to use as the machine's name in the bolt inventory file. Defaults to the machine name.
* `modulepath`
  * Description: A string containing the path to bolt modules
* `tmpdir`
  * Description: A string containing the directory to upload and execute temporary files on the target
* `verbose`
  * Description: A boolean which controls if bolt will output verbose logs
* `debug`
  * Description: A boolean which controls if bolt will output debug logs
* `run_as`
  * Description: A string containing the user to run commands as on the machine
* `args`
  * Description: A string containing additional arguments to be passed into the bolt command
* `features`
  * Description: An array containing the capabilities of the target that can be used to select a specific task implementation.
* `vars`
  * Description: A hash containing arbitrary data that may be passed to run_* functions or used for logic in plans
* `facts`
  * Description: A hash containing observed information about the target including what can be collected by Facter

**Deprecated Parameters**

* `node_list`
  * Replaced by `target_list`
* `nodes`
  * Replaced by `targets`

Config Builder
--------------

This module also supports the [oscar/config_builder](https://github.com/oscar-stack/vagrant-config_builder) plugin for configuration. If [oscar/config_builder](https://github.com/oscar-stack/vagrant-config_builder) is installed, bolt can be configured similar to the [Configuration Options section](#configuration-options) with a few small differences.

### Configuration

The configuration can be specified at the root, VM, and Provisioner levels.

An example of this configuration is below.

~~~ruby
---
# VM Default level config
vm_defaults:
  bolt:
    run_as: root
vms:
 - name: server
    # VM level config
    bolt:
      user: vagrant
      tmpdir: /tmp
      port: 1234
    provisioners:
      # Bolt provisioner
      - type: bolt
        command: task
        name: facts
~~~

### Trigger Configuration

Bolt triggers cab be configured at the root or within a VM object. To configure a bolt trigger a few additional params are required.

* `trigger_type`
  * Description: A symbol of the trigger type.
  * Valid Values: `:before` or `:after`
* `trigger_commands`
  * Description: An array of symbols for the commands to run the trigger on
  * Valid Values: An array of symbols such as `[:up, :provision, :halt]`

These will live under the `bolt_triggers` namespace which exists at the root and VM levels. `bolt_triggers` accepts an array of bolt triggers. Below is an example of using a VM level trigger for a specific VM.

~~~ruby
---
vms:
 - name: server
    bolt_triggers:
      - trigger_type: :after
        trigger_commands:
          - :provision
          - :up
        command: task
        name: facts
~~~

Below is an example of using a VM default trigger, which will apply to all machines.

~~~ruby
---
vm_defaults:
  bolt_triggers:
    - trigger_type: :after
      trigger_commands:
        - :provision
        - :up
      command: task
      name: facts
vms:
  - name: server
~~~

Commands
--------

Vagrant bolt comes with a single command that helps to run ad-hoc bolt commands. The `vagrant bolt` command is available to run bolt commands locally using the inventory file for the vagrant machines.

The format of the command is below.

~~~shell
Usage: vagrant bolt <options> [bolt options]

Options:

    -u, --[no-]updateinventory       Update the inventory file (defaults to false)
~~~

The command can be used to deploy the Puppetfile, for example.

~~~shell
vagrant bolt puppetfile install
~~~

It can be used to run ad-hoc tasks on a target by specifying the target by its machine name.

~~~shell
vagrant bolt -u task run facts -n server
~~~

The `--updateinventory` flag will regenerate the inventory file from the active running machines, however it defaults to being off. In the example above, the inventory file will be updated prior to running the task.

All arguments except for the `-u` will be passed to bolt, so a bolt command like the example below can be run.

~~~shell
vagrant bolt command run 'date' -n agent,master
~~~

Other Use Cases
---------------

There are some other use cases for Vagrant Bolt. One of which is to not use the triggers or provisioning to run bolt commands on the targets, but to manage the inventory file for manual testing. This can easily be accomplished by using a trigger to manage the `inventory.yaml` file and specifying the configuration for the targets in the config based on the options above. Below is an example trigger that will manage a `./inventory.yaml` file for use with external bolt commands.

~~~ruby
require 'vagrant-bolt'
Vagrant.configure("2") do |config|
  config.vm.box = "alpine/alpine64"

  config.trigger.after :up, :provision, :halt, :destroy do |trigger|
    trigger.name = "Manage a seperate inventory file"
    trigger.ruby do |env, machine|
      VagrantBolt::Util::Bolt.update_inventory_file(
        env,
        File.expand_path('inventory.yaml', File.dirname(__FILE__)),
      )
    end
  end
config.vm.define 'server'
end
~~~

Installation
------------

The plugin can be installed through vagrant's plugin manager. Please ensure to meet the requirements prior to installing `vagrant-bolt`.

~~~shell
vagrant plugin install vagrant-bolt
~~~

Requirements
------------

* Vagrant 2.2.0+ is required for this plugin.
* Bolt 1.10+ needs to be installed on the platform machine and accessible on the path. Use the `bolt_exe` config parameter if it is not on the path.
* Ruby 2.3+

Known Issues
------------

* Machine names with hyphens in them are not valid until bolt 1.10.0. Please upgrade to Bolt 1.10.0+ to use hyphens in the machine names.
