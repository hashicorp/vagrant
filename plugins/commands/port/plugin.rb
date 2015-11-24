require "vagrant"

module VagrantPlugins
  module CommandPort
    class Plugin < Vagrant.plugin("2")
      name "port command"
      description <<-DESC
      The `port` command displays guest port mappings.
      DESC

      command("port") do
        require_relative "command"
        self.init!
        Command
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path("../locales/en.yml", __FILE__)
        I18n.reload!
        @_init = true
      end
    end
  end
end
