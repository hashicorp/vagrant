module VagrantPlugins
  module DockerProvider
    module Action
      class PrepareNFSValidIds
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::nfs")
        end

        def call(env)
          machine = env[:machine]
          env[:nfs_valid_ids] = machine.provider.driver.all_containers

          @app.call(env)
        end
      end
    end
  end
end
