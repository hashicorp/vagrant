require "vagrant"
require 'vagrant/util/platform'

require Vagrant.source_root.join("plugins/hosts/bsd/host")

module VagrantPlugins
  module HostFreeBSD
    class Host < VagrantPlugins::HostBSD::Host
      class FreeBSDHostError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.hosts.freebsd")
      end

      include Vagrant::Util
      include Vagrant::Util::Retryable

      def self.match?
        Vagrant::Util::Platform.freebsd?
      end

      # Normal, mid-range precedence.
      def self.precedence
        5
      end

      def nfs_export(id, ip, folders)
        folders.each do |folder_name, folder_values|
          if folder_values[:hostpath] =~ /\s+/
            raise FreeBSDHostError, :_key => :nfs_whitespace
          end
        end

        super
      end

      def initialize(*args)
        super

        @nfs_restart_command = "sudo /etc/rc.d/mountd onereload"
        @nfs_exports_template = "nfs/exports_freebsd"
      end
    end
  end
end
