require "vagrant"

module VagrantPlugins
  module HostRedHat
    class Plugin < Vagrant.plugin("2")
      name "Red Hat Enterprise Linux host"
      description "Red Hat Enterprise Linux host support."

      host("redhat", "linux") do
        require File.expand_path("../host", __FILE__)
        Host
      end

      # Linux-specific helpers we need to determine paths that can
      # be overriden.
      host_capability("redhat", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("redhat", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
