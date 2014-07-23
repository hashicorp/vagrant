module VagrantPlugins
  module GuestSuse
    module Cap
      class NetworkScriptsDir
        def self.network_scripts_dir(_machine)
          '/etc/sysconfig/network/'
        end
      end
    end
  end
end
