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
          box_url   = env[:box_url]
          box_added = env[:box_added]

          # TODO: Persist box_url / provider / datetime

          @app.call(env)
        end
      end
    end
  end
end
