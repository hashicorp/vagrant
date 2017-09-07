require "vagrant"

module VagrantPlugins
  module HostSolus
    class Plugin < Vagrant.plugin("2")
      name "Solus host"
      description "Solus host support."

      host("solus", "linux") do
        require_relative "host"
        Host
      end

      host_capability("solus", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      # Linux-specific helpers we need to determine paths that can
      # be overriden.
      host_capability("solus", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("solus", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
