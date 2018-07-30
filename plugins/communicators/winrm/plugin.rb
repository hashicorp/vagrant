require "vagrant"

module VagrantPlugins
  module CommunicatorWinRM
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "winrm communicator"
      description <<-DESC
      This plugin allows Vagrant to communicate with remote machines using
      WinRM.
      DESC

      communicator("winrm") do
        require File.expand_path("../communicator", __FILE__)
        init!
        Communicator
      end

      config("winrm") do
        require_relative "config"
        Config
      end

      protected

      def self.init!
        return if defined?(@_init)
        @_init = true

        # Setup the I18n
        I18n.load_path << File.expand_path(
          "templates/locales/comm_winrm.yml", Vagrant.source_root)
        I18n.reload!

        # Check if vagrant-winrm plugin is installed and
        # output warning to user if found
        if !ENV["VAGRANT_IGNORE_WINRM_PLUGIN"] &&
            Vagrant::Plugin::Manager.instance.installed_plugins.keys.include?("vagrant-winrm")
            $stderr.puts <<-EOF
WARNING: Vagrant has detected the `vagrant-winrm` plugin. Vagrant ships with
WinRM support builtin and no longer requires the `vagrant-winrm` plugin. To
prevent unexpected errors please uninstall the `vagrant-winrm` plugin using
the command shown below:

  vagrant plugin uninstall vagrant-winrm

To disable this warning, set the environment variable `VAGRANT_IGNORE_WINRM_PLUGIN`
EOF
        end
        # Load the WinRM gem
        require "vagrant/util/silence_warnings"
        Vagrant::Util::SilenceWarnings.silence! do
          require "winrm"
        end
      end

      # @private
      # Reset the cached init value. This is not considered a public
      # API and should only be used for testing.
      def self.reset!
        send(:remove_instance_variable, :@_init)
      end
    end
  end
end
