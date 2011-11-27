module Vagrant
  class Action
    module VM
      # Middleware which verifies that the VM has the proper guest additions
      # installed and prints a warning if they're not detected or if the
      # version does not match the installed VirtualBox version.
      class CheckGuestAdditions
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Use the raw interface for now, while the virtualbox gem
          # doesn't support guest properties (due to cross platform issues)
          version = env["vm"].vm.interface.get_guest_property_value("/VirtualBox/GuestAdd/Version")
          if version.empty?
            env.ui.warn I18n.t("vagrant.actions.vm.check_guest_additions.not_detected")
          else
            # Strip the -OSE/_OSE off from the guest additions
            if version != VirtualBox.version.gsub(/[-_]ose/i, '')
              env.ui.warn(I18n.t("vagrant.actions.vm.check_guest_additions.version_mismatch",
                                 :guest_version => version,
                                 :virtualbox_version => VirtualBox.version))
            end
          end

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
