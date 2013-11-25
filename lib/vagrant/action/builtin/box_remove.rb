require "log4r"

module Vagrant
  module Action
    module Builtin
      # This middleware will remove a box for a given provider.
      class BoxRemove
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::box_remove")
        end

        def call(env)
          box_name     = env[:box_name]
          box_provider = env[:box_provider].to_sym

          box = nil
          begin
            box = env[:box_collection].find(box_name, box_provider)
          rescue Vagrant::Errors::BoxUpgradeRequired
            @env.boxes.upgrade(box_name)
            retry
          end

          raise Vagrant::Errors::BoxNotFound, :name => box_name, :provider => box_provider if !box
          env[:ui].info(I18n.t("vagrant.commands.box.removing",
                              :name => box_name,
                              :provider => box_provider))
          box.destroy!

          # Passes on the removed box to the rest of the middleware chain
          env[:box_removed] = box
          @app.call(env)
        end
      end
    end
  end
end
