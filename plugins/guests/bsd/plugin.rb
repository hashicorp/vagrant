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

      guest_capability(:bsd, :insert_public_key) do
        require_relative "cap/insert_public_key"
        Cap::InsertPublicKey
      end

      guest_capability(:bsd, :mount_nfs_folder) do
        require_relative "cap/nfs"
        Cap::NFS
      end
    end
  end
end
