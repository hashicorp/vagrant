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

      def self.initialize_winrm
        # Not all versions of GSSAPI support all of the GSSAPI methods, so
        # temporarily disable warnings while loading the gsapi gem.
        silence_warnings do
          require "winrm"
        end
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/comm_winrm.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end

      # Sets $VERBOSE to nil for the duration of the block and back to its original
      # value afterwards.
      def self.silence_warnings()
        old_verbose, $VERBOSE = $VERBOSE, nil
        yield
      ensure
        $VERBOSE = old_verbose
      end

    end
  end
end

# We need to initialize winrm upfront, see issue #3390
VagrantPlugins::CommunicatorWinRM::Plugin.initialize_winrm()
