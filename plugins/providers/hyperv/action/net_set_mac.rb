module VagrantPlugins
  module HyperV
    module Action
      class NetSetMac
        def initialize(app, env)
          @app = app
        end

        def call(env)
          mac = env[:machine].provider_config.mac
          if mac
            env[:ui].info("[Settings] [Network Adapter] Setting MAC address to: #{mac}")
            env[:machine].provider.driver.net_set_mac(mac)
          end  
          @app.call(env)
        end
      end
    end
  end
end
