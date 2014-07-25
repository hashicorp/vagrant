module VagrantPlugins
  module GuestRedHat
    module Cap
      class NetworkScriptsDir
        def self.network_scripts_dir(_machine)
          '/etc/sysconfig/network-scripts'
        end
      end
    end
  end
end
