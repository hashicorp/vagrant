module Vagrant
  module Action
    module VM
      class ClearNetworkInterfaces
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Create the adapters array to make all adapters nothing.
          # We do adapters 2 to 8 because that is every built-in adapter
          # excluding the NAT adapter on port 1 which Vagrant always
          # expects to exist.
          adapters = []
          2.upto(8).each do |i|
            adapters << {
              :adapter => i,
              :type    => :none
            }
          end

          # "Enable" all the adapters we setup.
          env[:ui].info I18n.t("vagrant.actions.vm.clear_network_interfaces.deleting")
          env[:vm].driver.enable_adapters(adapters)

          @app.call(env)
        end
      end
    end
  end
end
