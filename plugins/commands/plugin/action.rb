require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This middleware sequence will remove all plugins.
      def self.action_expunge
        Vagrant::Action::Builder.new.tap do |b|
          b.use ExpungePlugins
        end
      end

      # This middleware sequence will install a plugin.
      def self.action_install
        Vagrant::Action::Builder.new.tap do |b|
          b.use InstallGem
        end
      end

      # This middleware sequence licenses paid addons.
      def self.action_license
        Vagrant::Action::Builder.new.tap do |b|
          b.use PluginExistsCheck
          b.use LicensePlugin
        end
      end

      # This middleware sequence will list all installed plugins.
      def self.action_list
        Vagrant::Action::Builder.new.tap do |b|
          b.use ListPlugins
        end
      end

      # This middleware sequence will repair installed plugins.
      def self.action_repair
        Vagrant::Action::Builder.new.tap do |b|
          b.use RepairPlugins
        end
      end

      # This middleware sequence will uninstall a plugin.
      def self.action_uninstall
        Vagrant::Action::Builder.new.tap do |b|
          b.use PluginExistsCheck
          b.use UninstallPlugin
        end
      end

      # This middleware sequence will update a plugin.
      def self.action_update
        Vagrant::Action::Builder.new.tap do |b|
          b.use UpdateGems
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :ExpungePlugins, action_root.join("expunge_plugins")
      autoload :InstallGem, action_root.join("install_gem")
      autoload :LicensePlugin, action_root.join("license_plugin")
      autoload :ListPlugins, action_root.join("list_plugins")
      autoload :PluginExistsCheck, action_root.join("plugin_exists_check")
      autoload :RepairPlugins, action_root.join("repair_plugins")
      autoload :UninstallPlugin, action_root.join("uninstall_plugin")
      autoload :UpdateGems, action_root.join("update_gems")
    end
  end
end
