require "vagrant"

module VagrantPlugins
  module HostVoid
    class Plugin < Vagrant.plugin("2")
      name "Void host"
      description "Void linux host support."

      host("void", "linux") do
        require_relative "host"
        Host
      end

      host_capability("void", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("void", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("void", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
