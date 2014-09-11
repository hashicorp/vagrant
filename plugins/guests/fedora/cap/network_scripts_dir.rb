module VagrantPlugins
  module GuestFedora
    module Cap
      class NetworkScriptsDir
        # The path to the directory with the network configuration scripts.
        # This is pulled out into its own directory since there are other
        # operating systems (SUSE) which behave similarly but with a different
        # path to the network scripts.
        def self.network_scripts_dir(machine)
          "/etc/sysconfig/network-scripts"
        end
      end
    end
  end
end
