module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class CheckGuestAdditions
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Use the raw interface for now, while the virtualbox gem
          # doesn't support guest properties (due to cross platform issues)
          version = env[:machine].provider.driver.read_guest_additions_version
          if !version
            env[:ui].warn I18n.t("vagrant.actions.vm.check_guest_additions.not_detected")
          else
            # Strip the -OSE/_OSE off from the guest additions and the virtual box
            # version since all the matters are that the version _numbers_ match up.
            guest_version, vb_version = [version, env[:machine].provider.driver.version].map do |v|
              v.gsub(/[-_]ose/i, '')
            end

            if guest_version != vb_version
              env[:ui].warn(I18n.t("vagrant.actions.vm.check_guest_additions.version_mismatch",
                                   :guest_version => version,
                                   :virtualbox_version => vb_version))
            end
          end

          # Continue
          @app.call(env)
        end

      end
    end
  end
end
