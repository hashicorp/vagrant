require "fileutils"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Export
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          raise Vagrant::Errors::VMPowerOffToPackage if \
            @env[:machine].state.id != :poweroff

          export

          @app.call(env)
        end

        def export
          @env[:ui].info I18n.t("vagrant.actions.vm.export.exporting")
          @env[:machine].provider.driver.export(ovf_path) do |progress|
            @env[:ui].clear_line
            @env[:ui].report_progress(progress.percent, 100, false)
          end

          # Clear the line a final time so the next data can appear
          # alone on the line.
          @env[:ui].clear_line
        end

        def ovf_path
          File.join(@env["export.temp_dir"], "box.ovf")
        end
      end
    end
  end
end
