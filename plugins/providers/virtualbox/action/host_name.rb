module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class HostName
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @app.call(env)

          host_name = env[:machine].config.vm.host_name
          if !host_name.nil?
            env[:ui].info I18n.t("vagrant.actions.vm.host_name.setting")
            env[:machine].guest.change_host_name(host_name)
          end
        end
      end
    end
  end
end
