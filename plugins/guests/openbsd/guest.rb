require "vagrant"

require Vagrant.source_root.join("plugins/guests/linux/guest")

module VagrantPlugins
  module GuestOpenBSD
    class Guest < VagrantPlugins::GuestLinux::Guest
      def halt
        vm.channel.sudo("shutdown -p -h now")
      end
    end
  end
end
