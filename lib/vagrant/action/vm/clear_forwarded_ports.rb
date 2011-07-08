module Vagrant
  class Action
    module VM
      class ClearForwardedPorts
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          env["config"].vm.customize do |vm|
            env.ui.info I18n.t("vagrant.actions.vm.clear_forward_ports.deleting")

            vm.network_adapters.each do |na|
              na.nat_driver.forwarded_ports.dup.each do |fp|
                fp.destroy
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
