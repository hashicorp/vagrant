module Vagrant
  module Actions
    module VM
      class Export < Base
        attr_reader :temp_dir

        def execute!
          setup_temp_dir
          export
        end

        def setup_temp_dir
          @temp_dir = File.join(Env.tmp_path, Time.now.to_i.to_s)

          logger.info "Creating temporary directory for export..."
          FileUtils.mkpath(temp_dir)

          @runner.invoke_callback(:set_export_temp_path, @temp_dir)
        end

        def ovf_path
          File.join(temp_dir, Vagrant.config.vm.box_ovf)
        end

        def export
          logger.info "Exporting VM to #{ovf_path} ..."
          @runner.export(ovf_path)
        end
      end
    end
  end
end
