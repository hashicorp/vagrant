require 'fileutils'

module Vagrant
  module Action
    module Box
      class Destroy
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          env.ui.info I18n.t("vagrant.actions.box.destroy.destroying", :name => env["box"].name)
          FileUtils.rm_rf(env["box"].directory)

          @app.call(env)
        end
      end
    end
  end
end
