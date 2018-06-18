module VagrantPlugins
  module HyperV
    module Action
      class DeleteVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info("Deleting the machine...")
          env[:machine].provider.driver.delete_vm
          # NOTE: We remove the data directory and recreate it
          #       to overcome an issue seen when running within
          #       the WSL. Hyper-V will successfully remove the
          #       VM and the files will appear to be gone, but
          #       on a subsequent up, they will cause collisions.
          #       This forces them to be gone for real.
          FileUtils.rm_rf(env[:machine].data_dir)
          FileUtils.mkdir_p(env[:machine].data_dir)
          @app.call(env)
        end
      end
    end
  end
end
