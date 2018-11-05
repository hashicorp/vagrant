require 'vagrant/util/platform'

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # Checks that VirtualBox is installed and ready to be used.
      class CheckVirtualbox
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::provider::virtualbox")
        end

        def call(env)
          # This verifies that VirtualBox is installed and the driver is
          # ready to function. If not, then an exception will be raised
          # which will break us out of execution of the middleware sequence.
          Driver::Meta.new.verify!

          if Vagrant::Util::Platform.windows? && Vagrant::Util::Platform.windows_hyperv_enabled?
            @logger.error("Virtualbox and Hyper-V cannot be used together at the same time on Windows and will result in a system crash.")

            raise Vagrant::Errors::HypervVirtualBoxError
          end

          # Carry on.
          @app.call(env)
        end
      end
    end
  end
end
