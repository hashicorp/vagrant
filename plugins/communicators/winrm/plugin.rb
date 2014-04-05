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

        # Load the WinRM gem
        require "vagrant/util/silence_warnings"
        Vagrant::Util::SilenceWarnings.silence! do
          require "winrm"
        end
      end
    end
  end
end
