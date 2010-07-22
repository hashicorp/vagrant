module Vagrant
  class Action
    module VM
      class Export
        attr_reader :temp_dir

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env

          return env.error!(:vm_power_off_to_package) if !@env["vm"].vm.powered_off?
          return if env.error?

          setup_temp_dir
          export

          @app.call(env) if !env.error?

          cleanup
        end

        def cleanup
          if temp_dir && File.exist?(temp_dir)
            FileUtils.rm_rf(temp_dir)
          end
        end

        def setup_temp_dir
          @env.logger.info "Creating temporary directory for export..."
          @temp_dir = @env["export.temp_dir"] = File.join(@env.env.tmp_path, Time.now.to_i.to_s)
          FileUtils.mkpath(@env["export.temp_dir"])
        end

        def export
          @env.logger.info "Exporting VM to #{ovf_path}..."
          @env["vm"].vm.export(ovf_path) do |progress|
            @env.logger.report_progress(progress.percent, 100, false)
          end
        ensure
          @env.logger.clear_progress
        end

        def ovf_path
          File.join(@env["export.temp_dir"], @env.env.config.vm.box_ovf)
        end
      end
    end
  end
end
