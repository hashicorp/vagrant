require "vagrant"
require 'vagrant_cloud'
require Vagrant.source_root.join("plugins/commands/cloud/util")
require Vagrant.source_root.join("plugins/commands/cloud/client/client")

module VagrantPlugins
  module CloudCommand
    class Plugin < Vagrant.plugin("2")
      name "vagrant-cloud"
      description <<-DESC
      Provides the cloud command and internal API access to Vagrant Cloud.
      DESC

      command(:cloud) do
        require_relative "root"
        init!
        Command::Root
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
