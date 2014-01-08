require "vagrant"

module VagrantPlugins
  module HostSlackware
    class Plugin < Vagrant.plugin("2")
      name "Slackware host"
      description "Slackware and derivertives host support."

      host("slackware", "linux") do
        require File.expand_path("../host", __FILE__)
        Host
      end

      # Linux-specific helpers we need to determine paths that can
      # be overriden.
      host_capability("slackware", "nfs_check_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end

      host_capability("slackware", "nfs_start_command") do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
