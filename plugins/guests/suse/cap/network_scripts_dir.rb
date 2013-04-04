module VagrantPlugins
  module GuestSuse
    module Cap
      class NetworkScriptsDir
        def self.network_scripts_dir(machine)
          "/etc/sysconfig/network/"
        end
      end
    end
  end
end
