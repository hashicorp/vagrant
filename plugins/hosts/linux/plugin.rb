require "vagrant"

module VagrantPlugins
  module HostLinux
    class Plugin < Vagrant.plugin("2")
      name "Linux host"
      description "Linux host support."

      host("linux") do
        require_relative "host"
        Host
      end

      host_capability("linux", "nfs_export") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("linux", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("linux", "nfs_prune") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("linux", "rdp_client") do
        require_relative "cap/rdp"
        Cap::RDP
      end

      # Linux-specific helpers we need to determine paths that can
      # be overriden.
      host_capability("linux", "nfs_apply_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("linux", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("linux", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
