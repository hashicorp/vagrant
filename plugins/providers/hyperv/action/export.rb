require "fileutils"

module VagrantPlugins
  module HyperV
    module Action
      class Export
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          @env[:ui].info @env[:machine].state.id.to_s

          raise Vagrant::Errors::VMPowerOffToPackage if
            @env[:machine].state.id != :off

          export

          @app.call(env)
        end

        def export
          @env[:ui].info I18n.t("vagrant.actions.vm.export.exporting")
          export_tmp_dir = Vagrant::Util::Platform.wsl_to_windows_path(@env["export.temp_dir"])
          @env[:machine].provider.driver.export(export_tmp_dir) do |progress|
            @env[:ui].rewriting do |ui|
              ui.clear_line
              ui.report_progress(progress.percent, 100, false)
            end
          end

          # Clear the line a final time so the next data can appear
          # alone on the line.
          @env[:ui].clear_line
        end

      end
    end
  end
end
