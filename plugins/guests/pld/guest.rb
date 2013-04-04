require "vagrant"

require Vagrant.source_root.join("plugins/guests/redhat/guest")

module VagrantPlugins
  module GuestPld
    class Guest < VagrantPlugins::GuestRedHat::Guest
      def detect?(machine)
        machine.communicate.test("cat /etc/pld-release")
      end

      def network_scripts_dir
        '/etc/sysconfig/interfaces/'
      end
    end
  end
end
