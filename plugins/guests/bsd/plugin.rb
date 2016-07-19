require "vagrant"

module VagrantPlugins
  module GuestBSD
    class Plugin < Vagrant.plugin("2")
      name "BSD-based guest"
      description "BSD-based guest support."

      guest(:bsd) do
        require_relative "guest"
        Guest
      end

      guest_capability(:bsd, :halt) do
        require_relative "cap/halt"
        Cap::Halt
      end

      guest_capability(:bsd, :insert_public_key) do
        require_relative "cap/public_key"
        Cap::PublicKey
      end

      guest_capability(:bsd, :mount_nfs_folder) do
        require_relative "cap/nfs"
        Cap::NFS
      end

      guest_capability(:bsd, :mount_virtualbox_shared_folder) do
        require_relative "cap/virtualbox"
        Cap::VirtualBox
      end

      guest_capability(:bsd, :remove_public_key) do
        require_relative "cap/public_key"
        Cap::PublicKey
      end
    end
  end
end
