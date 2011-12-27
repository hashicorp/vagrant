require 'fileutils'

module Vagrant
  module Action
    module VM
      class Export
        attr_reader :temp_dir

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env

          raise Errors::VMPowerOffToPackage if @env["vm"].state != :poweroff

          setup_temp_dir
          export

          @app.call(env)

          recover(env) # called to cleanup temp directory
        end

        def recover(env)
          if temp_dir && File.exist?(temp_dir)
            FileUtils.rm_rf(temp_dir)
          end
        end

        def setup_temp_dir
          @env[:ui].info I18n.t("vagrant.actions.vm.export.create_dir")
          @temp_dir = @env["export.temp_dir"] = @env[:tmp_path].join(Time.now.to_i.to_s)
          FileUtils.mkpath(@env["export.temp_dir"])
        end

        def export
          @env[:ui].info I18n.t("vagrant.actions.vm.export.exporting")
          @env["vm"].driver.export(ovf_path) do |progress|
            @env[:ui].report_progress(progress.percent, 100, false)
          end
        end

        def ovf_path
          File.join(@env["export.temp_dir"], "box.ovf")
        end
      end
    end
  end
end
