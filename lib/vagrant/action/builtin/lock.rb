module Vagrant
  module Action
    module Builtin
      # This class creates a multi-process lock using `flock`. The lock
      # is active for the remainder of the middleware stack.
      class Lock
        def initialize(app, env, options=nil)
          @app     = app
          @options ||= options || {}
          raise ArgumentError, "Please specify a lock path" if !@options[:path]
          raise ArgumentError, "Please specify an exception." if !@options[:exception]
        end

        def call(env)
          lock_path = @options[:path]
          env_key   = "has_lock_#{lock_path}"

          if !env[env_key]
            # If we already have the key in our environment we assume the
            # lock is held by our middleware stack already and we allow
            # nesting.
            File.open(lock_path, "w+") do |f|
              # The file locking fails only if it returns "false." If it
              # succeeds it returns a 0, so we must explicitly check for
              # the proper error case.
              if f.flock(File::LOCK_EX | File::LOCK_NB) === false
                raise @options[:exception]
              end

              # Set that we gained the lock and call deeper into the
              # middleware, but make sure we UNSET the lock when we leave.
              begin
                env[env_key] = true
                @app.call(env)
              ensure
                env[env_key] = false
              end
            end
          else
            # Just call up the middleware because we already hold the lock
            @app.call(env)
          end
        end
      end
    end
  end
end
