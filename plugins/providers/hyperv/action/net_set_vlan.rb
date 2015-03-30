module VagrantPlugins
  module HyperV
    module Action
      class NetSetVLan
        def initialize(app, env)
          @app = app
        end

        def call(env)
          vlan_id = env[:machine].provider_config.vlan_id
          if  vlan_id
            env[:ui].info("[Settings] [Network Adapter] Setting Vlan ID to: #{vlan_id}")
            env[:machine].provider.driver.net_set_vlan(vlan_id)
          end  
          @app.call(env)
        end
      end
    end
  end
end
