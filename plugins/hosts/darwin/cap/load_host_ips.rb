module VagrantPlugins
  module HostDarwin
    module Cap
      class LoadHostIPs
        def self.load_host_ips(env)
          `ifconfig | grep 'inet ' | grep -v '127.0.0.1' | cut -d ' ' -f 2`.split
        end
      end
    end
  end
end
