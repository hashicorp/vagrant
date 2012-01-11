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
          # Delete the existing box
          env[:ui].info I18n.t("vagrant.actions.box.destroy.destroying", :name => env[:box_name])
          FileUtils.rm_rf(env[:box_directory])

          # Reload the box collection
          env[:box_collection].reload!

          @app.call(env)
        end
      end
    end
  end
end
