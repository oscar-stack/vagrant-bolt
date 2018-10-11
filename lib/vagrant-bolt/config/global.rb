require 'vagrant-bolt/config_default'

class VagrantBolt::Config::Global < Vagrant.plugin('2', :config)
  # Sets up the global configuration for Bolt

  # @!attribute [rw] username
  #   @return [String] The username to authenticate on the machine.
  #   @since 0.0.1
  attr_accessor :username

  # @!attribute [rw] password
  #   @return [String] The password to authenticate on the machine.
  #   @since 0.0.1
  attr_accessor :password

  # @!attribute [rw] sudopassword
  #   @return [String] The password to authenticate sudo on the machine.
  #   @since 0.0.1
  attr_accessor :sudopassword

  # @!attribute [rw] privatekey
  #   @return [String] The path of the privatekey to authenticate on the machine.
  #   @since 0.0.1
  attr_accessor :privatekey

  # @!attribute [rw] hostkeycheck
  #   @return [Boolean] If the connection should check the host key on the remote host (linux)
  #   @since 0.0.1
  attr_accessor :hostkeycheck

  # @!attribute [rw] ssl
  #   @return [Boolean] If the connection should use SSL on with WinRM (Windows)
  #   @since 0.0.1
  attr_accessor :ssl

  # @!attribute [rw] sslverify
  #   @return [Boolean] If the connection should verify SSL on with WinRM (Windows)
  #   @since 0.0.1
  attr_accessor :sslverify

  # @!attribute [rw] modulepath
  #   @return [String] The path to the modules. Defaults to `modules`.
  #   @since 0.0.1
  attr_accessor :modulepath

  # @!attribute [rw] tmpdir
  #   @return [String] The directory to upload and execute temporary files on the target
  #   @since 0.0.1
  attr_accessor :tmpdir

  # @!attribute [rw] verbose
  #   @return [Boolean] Shows verbose logging
  #   @since 0.0.1
  attr_accessor :verbose

  # @!attribute [rw] debug
  #   @return [Boolean] Shows debug logging
  #   @since 0.0.1
  attr_accessor :debug

  # @!attribute [rw] boltcommand
  #   @return [String] The full path to the bolt command. If not passed in, the bundled version will be used.
  #   @since 0.0.1
  attr_accessor :boltcommand

  def initialize
    @username     = UNSET_VALUE
    @password     = UNSET_VALUE
    @privatekey   = UNSET_VALUE
    @sudopassword = UNSET_VALUE
    @hostkeycheck = UNSET_VALUE
    @ssl          = UNSET_VALUE
    @sslverify    = UNSET_VALUE
    @modulepath   = UNSET_VALUE
    @tmpdir       = UNSET_VALUE
    @verbose      = UNSET_VALUE
    @debug        = UNSET_VALUE
    @boltcommand  = UNSET_VALUE
  end

  include VagrantBolt::ConfigDefault

  def finalize!
    set_default :@username, nil
    set_default :@password, nil
    set_default :@sudopassword, nil
    set_default :@privatekey, nil
    set_default :@hostkeycheck, false
    set_default :@ssl, false
    set_default :@sslverify, false
    set_default :@modulepath, 'modules'
    set_default :@tmpdir, nil
    set_default :@verbose, false
    set_default :@debug, false
    set_default :@boltcommand, nil
  end

  def validate(machine)
    errors = _detected_errors

    #validate_version(errors, machine)

    {"Bolt global config" => errors}
  end

  private
  # Validation Methods

end
