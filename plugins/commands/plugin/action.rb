require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This middleware sequence will install a plugin.
      def self.action_install
        Vagrant::Action::Builder.new.tap do |b|
          b.use BundlerCheck
          b.use InstallGem
          b.use PruneGems
        end
      end

      # This middleware sequence licenses paid addons.
      def self.action_license
        Vagrant::Action::Builder.new.tap do |b|
          b.use BundlerCheck
          b.use LicensePlugin
        end
      end

      # This middleware sequence will list all installed plugins.
      def self.action_list
        Vagrant::Action::Builder.new.tap do |b|
          b.use BundlerCheck
          b.use ListPlugins
        end
      end

      # This middleware sequence will uninstall a plugin.
      def self.action_uninstall
        Vagrant::Action::Builder.new.tap do |b|
          b.use BundlerCheck
          b.use UninstallPlugin
          b.use PruneGems
        end
      end

      # This middleware sequence will update a plugin.
      def self.action_update
        Vagrant::Action::Builder.new.tap do |b|
          b.use BundlerCheck
          b.use PluginExistsCheck
          b.use InstallGem
          b.use PruneGems
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :BundlerCheck, action_root.join("bundler_check")
      autoload :InstallGem, action_root.join("install_gem")
      autoload :LicensePlugin, action_root.join("license_plugin")
      autoload :ListPlugins, action_root.join("list_plugins")
      autoload :PluginExistsCheck, action_root.join("plugin_exists_check")
      autoload :PruneGems, action_root.join("prune_gems")
      autoload :UninstallPlugin, action_root.join("uninstall_plugin")
    end
  end
end
