module Vagrant
  module Action
    module Builtin
      class CloudInitWait

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::cloudinitwait")
        end

        def call(env)
          machine = env[:machine]
          @logger.info("Waiting for cloud init")
          if !machine.config.vm.cloud_init_configs.empty?
            machine.communicate.sudo("cloud-init status --wait", {:error_check => false})
          end
          @app.call(env)
        end
      end
    end
  end
end
