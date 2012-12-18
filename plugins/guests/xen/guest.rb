require "vagrant"

require Vagrant.source_root.join("plugins/guests/ubuntu/guest")

module VagrantPlugins
  module GuestXen
    class Guest < VagrantPlugins::GuestUbuntu::Guest
      def mount_shared_folder(name, guestpath, options)
          @logger.info('Skipping shared folder mount operation due to Virtual Box Guest Additions incompatibility with Xen.')
      end

      # Required so that the linux super class (super of ubuntu) doesn't find the ubuntu OS type during this call.
      def distro_dispatch
      end
    end
  end
end
