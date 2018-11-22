# frozen_string_literal: true

module VagrantBolt::Util
  module Machine
    # Machine based Utility Functions

    # Run a command locally with an execute
    # @param [String] The command to run
    # @param [Object] the UI object to write to
    def self.run_command(command, localui)
      localui.info(
        I18n.t('vagrant-bolt.provisioner.bolt.info.running_bolt',
               command: command),
      )

      # TODO: Update this so it works on windows platforms
      Vagrant::Util::Subprocess.execute(
        'bash',
        '-c',
        command,
        notify: [:stdout, :stderr],
        env: { PATH: ENV["VAGRANT_OLD_ENV_PATH"] },
      ) do |io_name, data|
        if io_name == :stdout
          localui.info data
        elsif io_name == :stderr
          localui.warn data
        end
      end
    end

    # Generate a list of active machines in the environment
    # @param [Object] env The Environment
    # @return [Array<Object>]
    def self.nodes_in_environment(env)
      env.active_machines.map { |vm|
        begin
          env.machine(*vm)
        rescue Vagrant::Errors::MachineNotFound
          nil
        end
      }.compact
    end

    # Return if the guest is windows. This only works for online machines
    # @param [Object] machine The machine
    # @return [Boolean]
    def self.windows?(machine)
      machine.config.vm.communicator == :winrm
    end

    # Return if the guest is running by checking the communicator
    # @param [Object] machine The machine
    # @return [Boolean]
    def self.running?(machine)
      # Taken from https://github.com/oscar-stack/vagrant-hosts/blob/master/lib/vagrant-hosts/provisioner/hosts.rb
      machine.communicate.ready?
    rescue Vagrant::Errors::VagrantError
      # WinRM will raise an error if the VM isn't running instead of
      # returning false (hashicorp/vagrant#6356).
      false
    end

    # Get the running machine object by the machine name
    # @param [Object] environment The enviornment to look in
    # @param [String, Symbol] name The name of the machine in the environment
    # @return [Object, nil] The object or nil if it is not found
    def self.machine_by_name(env, name)
      vm = env.active_machines.find { |m| m[0] == name.to_sym }
      env.machine(*vm) unless vm.nil?
    rescue Vagrant::Errors::MachineNotFound
      nil
    end
  end
end
