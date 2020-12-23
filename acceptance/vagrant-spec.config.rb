# frozen_string_literal: true

require 'pathname'
require 'vagrant-bolt'
require 'vagrant-spec/acceptance'

# Prevent tests from attempting to load plugins from a Vagrant install
# that may exist on the host system. We load required plugins below.
ENV['VAGRANT_DISABLE_PLUGIN_INIT'] = '1'

Vagrant::Spec::Acceptance.configure do |c|
  acceptance_dir = Pathname.new File.expand_path(__dir__)

  c.component_paths = ["#{acceptance_dir}/components"]
  c.skeleton_paths = ["#{acceptance_dir}/skeletons"]

  c.provider 'virtualbox',
             box: "#{acceptance_dir}/artifacts/virtualbox.box",
             env_vars: {
               'VBOX_USER_HOME' => '{{homedir}}',
             }
end
