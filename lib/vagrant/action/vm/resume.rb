module Vagrant
  module Action
    module VM
      class Resume
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env["vm"].vm.saved?
            env.ui.info I18n.t("vagrant.actions.vm.resume.resuming")
            env["actions"].run(Boot)
          end

          @app.call(env)
        end
      end
    end
  end
end
