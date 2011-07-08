module Vagrant
  class Action
    module VM
      class MatchMACAddress
        def initialize(app, env)
          @app = app
        end

        def call(env)
          raise Errors::VMBaseMacNotSpecified if !env.env.config.vm.base_mac

          env["config"].vm.customize do |vm|
            env.ui.info I18n.t("vagrant.actions.vm.match_mac.matching")
            vm.network_adapters.first.mac_address = env["config"].vm.base_mac
          end

          @app.call(env)
        end
      end
    end
  end
end
