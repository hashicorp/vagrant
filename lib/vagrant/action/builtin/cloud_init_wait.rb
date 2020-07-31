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
          cloud_init_wait_cmd = "cloud-init status --wait"
          if !machine.config.vm.cloud_init_configs.empty?
            if machine.communicate.test("command -v cloud-init")
              env[:ui].output(I18n.t("vagrant.cloud_init_waiting"))
              result = machine.communicate.sudo(cloud_init_wait_cmd, error_check: false)
              if result != 0
                raise Vagrant::Errors::CloudInitCommandFailed, cmd: cloud_init_wait_cmd, guest_name: machine.name
              end
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
