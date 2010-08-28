module Vagrant
  class Action
    module VM
      class Destroy
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env.ui.info "vagrant.actions.vm.destroy.destroying"
          env["vm"].vm.destroy(:destroy_medium => :delete)
          env["vm"].vm = nil
          env.env.update_dotfile

          @app.call(env)
        end
      end
    end
  end
end
