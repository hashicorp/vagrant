require "vagrant"

module VagrantPlugins
  module GuestOpenBSD
    class Plugin < Vagrant.plugin("2")
      name "OpenBSD guest"
      description "OpenBSD guest support."

      guest(:openbsd, :bsd) do
        require_relative "guest"
        Guest
      end

      guest_capability(:openbsd, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:openbsd, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:openbsd, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openbsd, :rsync_installed) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openbsd, :rsync_command) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openbsd, :rsync_post) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openbsd, :rsync_pre) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:openbsd, :shell_expand_guest_path) do
        require_relative "cap/shell_expand_guest_path"
        Cap::ShellExpandGuestPath
      end
    end
  end
end
