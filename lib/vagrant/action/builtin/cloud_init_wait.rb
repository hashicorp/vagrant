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
          if !machine.config.vm.cloud_init_configs.empty?
            if machine.communicate.test("command -v cloud-init")
              @logger.info("Waiting for cloud init")
              machine.communicate.sudo("cloud-init status --wait")
            else
              raise Vagrant::Errors::CloudInitNotFound, guest_name: machine.name
            end
          end
          @app.call(env)
        end
      end
    end
  end
end
