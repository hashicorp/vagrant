require "vagrant"

module VagrantPlugins
  module HostGentoo
    class Plugin < Vagrant.plugin("2")
      name "Gentoo host"
      description "Gentoo host support."

      host("gentoo", "linux") do
        require_relative "host"
        Host
      end

      # Linux-specific helpers we need to determine paths that can
      # be overriden.
      host_capability("gentoo", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("gentoo", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

    end
  end
end
