module Vagrant
  class Action
    module VM
      class MatchMACAddress
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env.ui.info I18n.t("vagrant.actions.vm.match_mac.matching")
          env["vm"].vm.network_adapters.first.mac_address = env.env.config.vm.base_mac
          env["vm"].vm.save

          @app.call(env)
        end
      end
    end
  end
end
