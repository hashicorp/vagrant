module Vagrant
  module Action
    module VM
      # Action that checks to make sure there are no forwarded port collisions,
      # and raises an exception if there is.
      class CheckPortCollisions
        def initialize(app, env)
          @app = app
        end

        def call(env)
          existing = env[:vm].driver.read_used_ports

          env[:vm].config.vm.forwarded_ports.each do |name, options|
            if existing.include?(options[:hostport].to_i)
              # We have a collision!
              raise Errors::ForwardPortCollisionResume
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
