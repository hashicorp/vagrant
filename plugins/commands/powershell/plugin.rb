require "vagrant"

module VagrantPlugins
  module CommandPS
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "powershell command"
      description <<-DESC
      The powershell command opens a remote PowerShell session to the
      machine if it supports powershell remoting.
      DESC

      command("powershell") do
        require_relative "command"
        init!
        Command
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path("templates/locales/command_ps.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
