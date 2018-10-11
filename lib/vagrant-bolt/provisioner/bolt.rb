require 'vagrant'
require 'vagrant/errors'

class VagrantBolt::Provisioner::Bolt < Vagrant.plugin('2', :provisioner)
  # Provision VMs with Bolt
  # @since 0.0.1

  def configure(root_config)
  # Do any root level config needed to the VM
  end

  def provision
    # Cache the ssh_info
    @ssh_info = @machine.ssh_info
    raise Vagrant::Errors::SSHNotReady if @ssh_info.nil?
    setup_overrides
    provision_task unless config.task.nil?
    provision_plan unless config.plan.nil?
  end

  def cleanup

  end

  private

  def setup_overrides
    config.username ||= @ssh_info[:username]
    config.privatekey ||= @ssh_info[:private_key_path][0]
    config.hostkeycheck ||= @ssh_info[:verify_host_key]
    config.nodes ||= "#{@ssh_info[:host]}:#{@ssh_info[:port]}"
  end

  def provision_task
    puts "Provisioning Task"
    command = "/opt/puppetlabs/bin/bolt task run #{config.task} -n #{config.nodes} -u #{config.username} --private-key #{config.privatekey} --no-host-key-check --modulepath #{config.modulepath}"
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

  def provision_plan
    puts "Provisioning Plan"
  end
end
