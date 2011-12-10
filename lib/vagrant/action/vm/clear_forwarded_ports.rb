module Vagrant
  module Action
    module VM
      class ClearForwardedPorts
        def initialize(app, env)
          @app = app
        end

        def call(env)
          proc = lambda do |vm|
            env[:ui].info I18n.t("vagrant.actions.vm.clear_forward_ports.deleting")

            vm.network_adapters.each do |na|
              na.nat_driver.forwarded_ports.dup.each do |fp|
                fp.destroy
              end
            end
          end

          env["vm.modify"].call(proc)
          @app.call(env)
        end
      end
    end
  end
end
