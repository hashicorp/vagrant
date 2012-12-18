module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class MessageNotRunning
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.commands.common.vm_not_running")
          @app.call(env)
        end
      end
    end
  end
end
