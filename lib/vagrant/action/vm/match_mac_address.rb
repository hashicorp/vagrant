module Vagrant
  module Action
    module VM
      class MatchMACAddress
        def initialize(app, env)
          @app = app
        end

        def call(env)
          raise Errors::VMBaseMacNotSpecified if !env[:vm].config.vm.base_mac

          # Create the proc which we want to use to modify the virtual machine
          env[:ui].info I18n.t("vagrant.actions.vm.match_mac.matching")
          env[:vm].driver.set_mac_address(env[:vm].config.vm.base_mac)

          @app.call(env)
        end
      end
    end
  end
end
