require "vagrant"

module VagrantPlugins
  module HostALT
    class Plugin < Vagrant.plugin("2")
      name "ALT Platform host"
      description "ALT Platform host support."

      host("alt", "linux") do
        require_relative "host"
        Host
      end

      host_capability("alt", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      # Linux-specific helpers we need to determine paths that can
      # be overriden.
      host_capability("alt", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("alt", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
