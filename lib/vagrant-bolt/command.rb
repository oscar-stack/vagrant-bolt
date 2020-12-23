# frozen_string_literal: true

require_relative 'util/bolt'
require_relative 'util/machine'
require_relative 'util/config'

class VagrantBolt::Command < Vagrant.plugin('2', :command)
  def self.synopsis
    "Calls the bolt executable with the given options"
  end

  def execute
    options = {}
    options[:update] = false

    parser = OptionParser.new do |o|
      o.banner = "Usage: vagrant bolt <options> [bolt options]"
      o.separator ""
      o.separator "Options:"
      o.separator ""

      o.on("-u", "--[no-]updateinventory", "Update the inventory file (defaults to false)") do |u|
        options[:update] = u
      end
    end

    # This is a hack. We are passing everything to bolt, but still allow for bolt options.
    # We just remove them from @argv here and use the rest.
    # This allows for not having to define a seperator as long as there are no argument colisions
    return if @argv.empty?

    args = @argv.dup
    begin
      parser.parse!(args)
    rescue OptionParser::InvalidOption
      retry
    end
    bolt_args = @argv - ['-u', '--updateinventory', '--no-updateinventory']

    VagrantBolt::Util::Bolt.update_inventory_file(@env) if options[:update]

    execute_bolt_command(bolt_args)
  end

  # Run a bolt command with the inventory path, and project
  # @param args [Array<String>] An array containing the bolt arguments
  def execute_bolt_command(args)
    bolt_exe = @env.vagrantfile.config.bolt.bolt_exe
    project = VagrantBolt::Util::Config.relative_path(@env.vagrantfile.config.bolt.project, @env.root_path)
    inventoryfile = VagrantBolt::Util::Bolt.inventory_file(@env)

    quoted_args = args.flatten.compact.map { |a| "'#{a}'" }
    command = [
      bolt_exe,
      quoted_args,
      '--project',
      project,
    ]
    command << ['--inventoryfile', "\'#{inventoryfile}\'"] if File.exist?(inventoryfile)
    VagrantBolt::Util::Machine.run_command(command.flatten.join(' '), @env.ui)
  end
end
