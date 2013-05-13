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
            # Read the versions
            versions = [version, env[:machine].provider.driver.version]

            # Strip of any -OSE or _OSE and read only the first two parts
            # of the version such as "4.2" in "4.2.0"
            versions.map! do |v|
              v     = v.gsub(/[-_]ose/i, '')
              match = /^(\d+\.\d+)\.(\d+)/.match(v)
              v     = match[1] if match
              v
            end

            guest_version = versions[0]
            vb_version    = versions[1]

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
