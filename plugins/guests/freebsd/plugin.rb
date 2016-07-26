require "vagrant"

module VagrantPlugins
  module GuestFreeBSD
    class Plugin < Vagrant.plugin("2")
      name "FreeBSD guest"
      description "FreeBSD guest support."

      guest(:freebsd, :bsd) do
        require_relative "guest"
        Guest
      end

      guest_capability(:freebsd, :change_host_name) do
        require_relative "cap/change_host_name"
        Cap::ChangeHostName
      end

      guest_capability(:freebsd, :configure_networks) do
        require_relative "cap/configure_networks"
        Cap::ConfigureNetworks
      end

      guest_capability(:freebsd, :rsync_install) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:freebsd, :rsync_installed) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:freebsd, :rsync_command) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:freebsd, :rsync_post) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:freebsd, :rsync_pre) do
        require_relative "cap/rsync"
        Cap::RSync
      end

      guest_capability(:freebsd, :shell_expand_guest_path) do
        require_relative "cap/shell_expand_guest_path"
        Cap::ShellExpandGuestPath
      end
    end
  end
end
