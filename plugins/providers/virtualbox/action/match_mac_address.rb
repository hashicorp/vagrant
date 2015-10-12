module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class MatchMACAddress
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # If we cloned, we don't need a base mac, it is already set!
          return @app.call(env) if env[:machine].config.vm.clone

          raise Vagrant::Errors::VMBaseMacNotSpecified if !env[:machine].config.vm.base_mac

          # Create the proc which we want to use to modify the virtual machine
          env[:ui].info I18n.t("vagrant.actions.vm.match_mac.matching")
          env[:machine].provider.driver.set_mac_address(env[:machine].config.vm.base_mac)

          @app.call(env)
        end
      end
    end
  end
end
