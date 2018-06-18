module VagrantPlugins
  module HyperV
    module Action
      class CheckAccess
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          env[:ui].output("Verifying Hyper-V is accessible...")
          result = env[:machine].provider.driver.execute(:check_hyperv_access,
            "Path" => Vagrant::Util::Platform.wsl_to_windows_path(env[:machine].data_dir).gsub("/", "\\")
          )
          if !result["result"]
            raise Errors::SystemAccessRequired,
              root_dir: result["root_dir"]
          end

          @app.call(env)
        end
      end
    end
  end
end
