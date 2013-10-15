module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Boot
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env
          
          init_only = false
          init_only = @env[:init_only] if env.has_key?(:init_only)
          
          if init_only
            raise Vagrant::Errors::InitOnlySet
          end

          boot_mode = @env[:machine].provider_config.gui ? "gui" : "headless"

          # Start up the VM and wait for it to boot.
          env[:ui].info I18n.t("vagrant.actions.vm.boot.booting")
          env[:machine].provider.driver.start(boot_mode)

          @app.call(env)
        end
      end
    end
  end
end
