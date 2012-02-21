module Vagrant
  module Action
    module General
      # Checks that virtualbox is installed and ready to be used.
      class CheckVirtualbox
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Certain actions may not actually have a VM, and thus no
          # driver, so we have to be clever about obtaining an instance
          # of the driver.
          driver = nil
          driver = env[:vm].driver if env[:vm]
          driver = Driver::VirtualBox.new(nil) if !driver

          # Verify that it is ready to go! This will raise an exception
          # if anything goes wrong.
          driver.verify!

          # Carry on.
          @app.call(env)
        end
      end
    end
  end
end
