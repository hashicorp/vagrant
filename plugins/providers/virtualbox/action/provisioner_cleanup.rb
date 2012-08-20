module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ProvisionerCleanup
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Instantiate all the enabled provisioners
          provisioners = env[:machine].config.vm.provisioners.map do |provisioner|
            provisioner.provisioner.new(env, provisioner.config)
          end

          # Call cleanup on each
          provisioners.each do |instance|
            instance.cleanup
          end

          @app.call(env)
        end
      end
    end
  end
end
