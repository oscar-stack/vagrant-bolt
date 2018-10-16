require 'vagrant'
require 'vagrant/errors'

class VagrantBolt::Provisioner::Bolt < Vagrant.plugin('2', :provisioner)
  # Provision VMs with Bolt
  # Creates a trigger for each bolt provioner

  def configure(root_config)
    merge_root_config(root_config.bolt)
    #TODO: Check for bolt command, etc
    ## triggers need the machine booted, or ruby code in vagrant 2.2.0 to work in configure
    # add_bolt_trigger
  end

  def provision
    setup_overrides
    # Use an execute locally for now
    deploy_puppetfile if config.deploypuppetfile
    run_bolt
  end

  def cleanup
    # We don't do any clean up for this provisioner
  end

  private

  # Merge the local and root_config settings into @config
  # Allow for setting defaults in the root_config. We merge them here.
  # @param [Object] root_bolt_config A bolt config object from the root_config
  def merge_root_config(root_bolt_config)
    result = config.class.new
    result = merge_config(result, root_bolt_config)
    result = merge_config(result, config)
    result.finalize!
    @config = result
  end

  # Since the configs have been finalized they will have `nil` values
  # instead of UNSET_VALUE
  # Merge two config objects overwriting nil objects
  # @param [Object] local The local config object
  # @param [Object] other The other config object
  # @return [Object] a merged result with local overriding other
  def merge_config(local, other)
    result = local.class.new
    [local, other].each do |obj|
      obj.instance_variables.each do |key|
        value = obj.instance_variable_get(key)
        result.instance_variable_set(key, value) if value != Vagrant::Plugin::V2::Config::UNSET_VALUE and value != nil
      end
    end
    return result
  end

  # Set up some connection defaults for connecting to the machine if values are not set
  def setup_overrides
    config.nodes = all_node_list(machine.env) if config.nodes == "ALL"
    ssh_info = @machine.ssh_info
    raise Vagrant::Errors::SSHNotReady if ssh_info.nil?
    config.nodes ||= "#{ssh_info[:host]}:#{ssh_info[:port]}"
    config.username ||= ssh_info[:username]
    config.privatekey ||= ssh_info[:private_key_path][0]
    config.hostkeycheck ||= ssh_info[:verify_host_key]
  end

  # Create a bolt command from the config
  # @return [String] The bolt command
  def create_command
    #TODO: add the rest of the options
    command = []
    command << config.boltcommand
    plan_or_task = config.task.nil? ? "plan run #{config.plan}" : "task run #{config.task}"
    command << plan_or_task
    command << "-u #{config.username}" unless config.username.nil?
    command << "--private-key #{config.privatekey}" unless config.privatekey.nil?
    host_key_check = (config.hostkeycheck == true) ? "--host-key-check" : "--no-host-key-check"
    command << host_key_check
    command << "--modulepath #{config.modulepath}"
    command << "-n #{config.nodes}"
    command << "--params \'#{config.parameters.to_json}\'" unless config.parameters.nil?
    command << "--run_as #{config.run_as}" unless config.run_as.nil?
    command.flatten.join(" ")
  end

  # Run bolt locally with an execute
  def run_bolt
    command = create_command
    machine.ui.info(
      I18n.t('vagrant-bolt.provisioner.bolt.info.running_bolt',
        :command => command,
        ))
    result = Vagrant::Util::Subprocess.execute(
        'bash',
        '-c',
        command,
        :notify => [:stdout, :stderr],
        :env => {PATH: ENV["VAGRANT_OLD_ENV_PATH"]},
      ) do |io_name, data|
          @machine.env.ui.info "[#{io_name}] #{data}"
        end
  end

  # Deploy the Puppetfile if it exists
  def deploy_puppetfile
    ## TODO: Convert this to a trigger that only runs once pre provision
    ## Currently it runs on the first configure
    ######## Does not fire the root or before trigger from this scope ########
    # if File.file?("#{config.boltdir}/Puppetfile")
    #   existing_trigger = machine.config.trigger.before_triggers.find { |t| t.name = "Deploying Puppetfile" }
    #   unless existing_trigger
    #     command = "#{config.boltcommand} puppetfile install --boltdir #{config.boltdir}"
    #     options = {
    #       name: "Deploying Puppetfile",
    #       run:  {
    #         inline: command
    #       }
    #     }
    #     trigger = generate_trigger(:provision, options)
    #     ##root_config.trigger.before_triggers << trigger
    #     machine.config.trigger.before_triggers << trigger
    #
    # end
    # else
    #   # "No Puppetfile exists; not updating"
    # end
    ######## End ########
    
    # Use an execute instead, but only do it once and update the root_config
    if File.file?("#{config.boltdir}/Puppetfile") #and root_config.bolt.deploypuppetfile
      machine.ui.info(I18n.t('vagrant-bolt.provisioner.bolt.info.deploying_puppetfile'))
      command = "#{config.boltcommand} puppetfile install --boltdir #{config.boltdir}"
      result = Vagrant::Util::Subprocess.execute(
          'bash',
          '-c',
          command,
          :notify => [:stdout, :stderr],
          :env => {PATH: ENV["VAGRANT_OLD_ENV_PATH"]},
        ) do |io_name, data|
          @machine.env.ui.info "[#{io_name}] #{data}"
        end
        #root_config.bolt.set_options({:deploypuppetfile => false})
    end
  end

  # Add a bolt trigger to the machine after provision triggers
  def add_bolt_trigger
    machine.ui.info(
      I18n.t('vagrant-bolt.provisioner.bolt.info.adding_trigger',
        :action => ":provision",
        :machine => machine.name,
        ))
    command = create_command
    options = map_trigger_options(command)
    trigger = generate_trigger(:provision, options)
    machine.config.trigger.after_triggers << trigger
  end

  # Generate a trigger Object
  # @param [Symbol] action the action to generate the trigger on
  # @param [Hash] options a hash of VagrantPlugins::Kernel_V2::VagrantConfigTrigger options
  # @return [Object] finalized VagrantPlugins::Kernel_V2::VagrantConfigTrigger object
  def generate_trigger(action, options)
    trigger = VagrantPlugins::Kernel_V2::VagrantConfigTrigger.new(action)
    trigger.set_options(options)
    trigger.finalize!
    return trigger
  end

  # Create a hash of options for a trigger object
  # @param [String] command The command to be passed to the inline run
  # @return [Hash]
  def map_trigger_options(command)
    options = {}
    options[:name] = "Bolt #{config.task}"
    options[:run] = {inline: command}
    return options
  end

  # Generate a CSV list of node:port addresses for all active nodes in the environment
  # @param [Object] env The Enviornment
  # @return [String]
  def all_node_list(env)
    nodes_in_environment(env).map { |vm|
      "#{vm.ssh_info[:host]}:#{vm.ssh_info[:port]}" unless vm.ssh_info.nil?
    }.compact.join(",")
  end

  # Generate a list of active machines in the environment
  # @param [Object] env The Environment
  # @return [Array[Object]]
  def nodes_in_environment(env)
    env.active_machines.map { |vm|
      begin
        env.machine(*vm)
      rescue Vagrant::Errors::MachineNotFound
        nil
      end
    }.compact
  end
end
