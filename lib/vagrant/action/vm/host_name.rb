module Vagrant
  class Action
    module VM
      class HostName
        def initialize(app, env, options=nil)
          @app = app
          env.merge!(options || {})
        end

        def call(env)
          @app.call(env)
          host_name = env["config"].vm.host_name
          if !host_name.nil?
            env.ui.info I18n.t("vagrant.actions.vm.host_name.setting")
            env["vm"].system.change_host_name(host_name)
          end
        end
      end
    end
  end
end