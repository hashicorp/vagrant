require 'fileutils'

module Vagrant
  class Action
    module Box
      class Destroy
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          env.ui.info "vagrant.actions.box.destroy.destroying", :name => env["box"].name
          FileUtils.rm_rf(env["box"].directory)

          @app.call(env)
        end
      end
    end
  end
end
