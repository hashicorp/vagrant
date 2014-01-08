require "vagrant"

module VagrantPlugins
  module HostArch
    class Plugin < Vagrant.plugin("2")
      name "Arch host"
      description "Arch host support."

      host("arch", "linux") do
        require_relative "host"
        Host
      end

      host_capability("arch", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      # Linux-specific helpers we need to determine paths that can
      # be overriden.
      host_capability("arch", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("arch", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
