require "log4r"

module Vagrant
  module Action
    module Builtin
      # This middleware will remove additional information about the base box
      # from state file
      class RemoveBoxInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::remove_box_info")
        end

        def call(env)
          box_removed    = env[:box_removed]
          box_state_file = env[:box_state_file]

          # Mark that we removed the box
          @logger.info("Removing the box from the state file...")
          box_state_file.remove_box(box_removed)

          @app.call(env)
        end
      end
    end
  end
end
