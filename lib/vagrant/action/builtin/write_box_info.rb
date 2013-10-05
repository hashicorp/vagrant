require "log4r"

module Vagrant
  module Action
    module Builtin
      # This middleware will persist some extra information about the base box
      class WriteBoxInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::write_box_info")
        end

        def call(env)
          box_url        = env[:box_url]
          box_added      = env[:box_added]
          box_state_file = env[:box_state_file]

          # Mark that we downloaded the box
          @logger.info("Adding the box to the state file...")
          box_state_file.add_box(box_added, box_url)

          @app.call(env)
        end
      end
    end
  end
end
