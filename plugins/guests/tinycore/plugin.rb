require "vagrant"

module VagrantPlugins
  module GuestTinyCore
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "TinyCore Linux guest."
      description "TinyCore Linux guest support."

      guest("tinycore", "linux")  do
        require File.expand_path("../guest", __FILE__)
        init!
        Guest
      end

      guest_capability("tinycore", "configure_networks") do
        require_relative "cap/configure_networks"
        init!
        Cap::ConfigureNetworks
      end

      guest_capability("tinycore", "halt") do
        require_relative "cap/halt"
        init!
        Cap::Halt
      end

      guest_capability("tinycore", "rsync_install") do
        require_relative "cap/rsync"
        init!
        Cap::RSync
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/guest_tinycore.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
