module Vagrant
  class Action
    module VM
      # Middleware which verifies that the VM has the proper guest additions
      # installed and prints a warning if they're not detected or if the
      # version does not match the installed VirtualBox version.
      class CheckGuestAdditions
        include Util

        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Use the raw interface for now, while the virtualbox gem
          # doesn't support guest properties (due to cross platform issues)
          version = env["vm"].vm.interface.get_guest_property_value("/VirtualBox/GuestAdd/Version")
          if version.empty?
            env.logger.error Translator.t(:vm_additions_not_detected)
          elsif version != VirtualBox.version
            env.logger.error Translator.t(:vm_additions_version_mismatch,
                                          :guest_additions_version => version,
                                          :virtualbox_version => VirtualBox.version)
          end

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
