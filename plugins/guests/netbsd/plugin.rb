require "vagrant"

module VagrantPlugins
  module GuestNetBSD
    class Plugin < Vagrant.plugin("2")
      name "NetBSD guest"
      description "NetBSD guest support."

      guest(:netbsd, :bsd) do
        require_relative "guest"
        Guest
      end

      guest_capability(:netbsd, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:netbsd, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:netbsd, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:netbsd, :rsync_installed) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:netbsd, :rsync_command) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:netbsd, :rsync_post) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:netbsd, :rsync_pre) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:netbsd, :shell_expand_guest_path) do
        require_relative "cap/shell_expand_guest_path"
        Cap::ShellExpandGuestPath
      end
    end
  end
end
