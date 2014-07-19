require "vagrant"

module VagrantPlugins
  module HostDarwin
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "Mac OS X host"
      description "Mac OS X host support."

      host("darwin", "bsd") do
        require_relative "host"
        init!
        Host
      end

      host_capability("darwin", "create_smb_share") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("darwin", "enable_smb_sharing") do
        require_relative "cap/smb"
        Cap::SMB
      end

      host_capability("darwin", "rdp_client") do
        require_relative "cap/rdp"
        Cap::RDP
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path("templates/locales/host_darwin.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
