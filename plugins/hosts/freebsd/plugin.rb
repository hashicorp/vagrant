require "vagrant"

module VagrantPlugins
  module HostFreeBSD
    class Plugin < Vagrant.plugin("2")
      name "FreeBSD host"
      description "FreeBSD host support."

      host("freebsd", "bsd") do
        require_relative "host"
        Host
      end

      host_capability("freebsd", "nfs_export") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      # BSD-specific helpers
      host_capability("freebsd", "nfs_exports_template") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("freebsd", "nfs_restart_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
