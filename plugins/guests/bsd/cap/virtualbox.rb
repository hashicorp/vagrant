module VagrantPlugins
  module GuestBSD
    module Cap
      class VirtualBox
        # BSD-based guests do not currently support VirtualBox synced folders.
        # Instead of raising an error about a missing capability, this defines
        # the capability and then provides a more detailed error message,
        # linking to sources on the Internet where the problem is
        # better-described.
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          raise Vagrant::Errors::VirtualBoxMountNotSupportedBSD
        end
      end
    end
  end
end
