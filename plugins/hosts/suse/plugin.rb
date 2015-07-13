require "vagrant"

module VagrantPlugins
  module HostSUSE
    class Plugin < Vagrant.plugin("2")
      name "SUSE host"
      description "SUSE host support."

      host("suse", "linux") do
        require_relative "host"
        Host
      end

      host_capability("suse", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("suse", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("suse", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
