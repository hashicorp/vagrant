module Vagrant
  module Action
    module Builtin
      class Disk
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::disk")
        end

        def call(env)
          machine = env[:machine]

          # Continue On
          @app.call(env)
        end
      end
    end
  end
end
