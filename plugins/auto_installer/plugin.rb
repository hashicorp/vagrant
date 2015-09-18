require "vagrant"

module VagrantPlugins
  module PluginAutoInstaller
    class Plugin < Vagrant.plugin("2")
      name to_s "Plugin Auto-Installer"

      description <<-DESC
      This (pseudo-plugin) code fragment is intended to be
      pasted into the top of your Vagrantfile to ensure your
      required manifest of plugins are automatically installed
      (or uninstalled) as your Vagrantfile expects.
      DESC

      # Only respond to actions that will create / boot / resume a box (not a halt or destroy,
      # for instance)
      [ :machine_action_boot,      :machine_action_provision, :machine_action_reload,
        :machine_action_resume,    :machine_action_start,     :machine_action_up,
        :provisioner_run
      ]. each do |event_name|
        action_hook("auto_install_plugins", event_name) do |hook|
            hook.prepend(ManifestChecker)
        end
      end

      config("auto_installer") do
        Config
      end
    end
  end
end
