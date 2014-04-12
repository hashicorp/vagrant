require "vagrant"

module VagrantPlugins
  module CommandRDP
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "rdp command"
      description <<-DESC
      The rdp command opens a remote desktop Window to the
      machine if it supports RDP.
      DESC

      command("rdp") do
        require File.expand_path("../command", __FILE__)
        init!
        Command
      end

      config("rdp") do
        require_relative "config"
        Config
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/command_rdp.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
