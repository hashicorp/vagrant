require "vagrant"

module VagrantPlugins
  module HostBSD
    class Plugin < Vagrant.plugin("2")
      name "BSD host"
      description "BSD host support."

      host("bsd") do
        require File.expand_path("../host", __FILE__)
        Host
      end

      host_capability("bsd", "nfs_export") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("bsd", "nfs_exports_template") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("bsd", "nfs_installed") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("bsd", "nfs_prune") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("bsd", "nfs_restart_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("bsd", "resolve_host_path") do
        require_relative "cap/path"
        Cap::Path
      end

      host_capability("bsd", "set_ssh_key_permissions") do
        require_relative "cap/ssh"
        Cap::SSH
      end
    end
  end
end
