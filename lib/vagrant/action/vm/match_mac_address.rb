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
          proc = lambda do |vm|
            env[:ui].info I18n.t("vagrant.actions.vm.match_mac.matching")
            vm.network_adapters.first.mac_address = env[:vm].config.vm.base_mac
          end

          # Add the proc to the modification chain
          env["vm.modify"].call(proc)

          @app.call(env)
        end
      end
    end
  end
end
