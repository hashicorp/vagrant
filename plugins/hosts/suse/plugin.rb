require "vagrant"

module VagrantPlugins
  module HostOpenSUSE
    class Plugin < Vagrant.plugin("2")
      name "OpenSUSE host"
      description "OpenSUSE host support."

      host("opensuse", "linux") do
        require_relative "host"
        Host
      end

      # Linux-specific helpers we need to determine paths that can
      # be overriden.
      host_capability("opensuse", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("opensuse", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
