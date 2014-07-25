module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class MatchMACAddress
        def initialize(app, _env)
          @app = app
        end

        def call(env)
          fail Vagrant::Errors::VMBaseMacNotSpecified unless env[:machine].config.vm.base_mac

          # Create the proc which we want to use to modify the virtual machine
          env[:ui].info I18n.t('vagrant.actions.vm.match_mac.matching')
          env[:machine].provider.driver.set_mac_address(env[:machine].config.vm.base_mac)

          @app.call(env)
        end
      end
    end
  end
end
