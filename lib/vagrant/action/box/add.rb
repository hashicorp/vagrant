module Vagrant
  module Action
    module Box
      # Adds a downloaded box file to the environment's box collection.
      # This handles unpacking the box. See {BoxCollection#add} for more
      # information.
      class Add
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env[:ui].info I18n.t("vagrant.actions.box.add.adding", :name => env[:box_name])

          begin
            env[:box_collection].add(env[:box_download_temp_path], env[:box_name])
          rescue Vagrant::Errors::BoxUpgradeRequired
            # Upgrade the box
            env[:box_collection].upgrade(env[:box_name])

            # Try adding it again
            retry
          end

          @app.call(env)
        end
      end
    end
  end
end
