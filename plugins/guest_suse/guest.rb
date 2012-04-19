module VagrantPlugins
  module GuestSuse
    class Guest < VagrantPlugins::GuestRedHat::Guest
      def network_scripts_dir
        '/etc/sysconfig/network/'
      end
    end
  end
end
