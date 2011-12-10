module Vagrant
  module Action
    module VM
      # This action sets the default name of a virtual machine. The default
      # name is the CWD of the environment plus a timestamp.
      class DefaultName
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Create the proc to setup the default name
          proc = lambda do |vm|
            vm.name = File.basename(env[:vm].env.cwd) + "_#{Time.now.to_i}"
          end

          env["vm.modify"].call(proc)

          @app.call(env)
        end
      end
    end
  end
end
