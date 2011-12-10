module Vagrant
  module Action
    module VM
      class Provision
        def initialize(app, env)
          @app = app
          @env = env
          @env["provision.enabled"] = true if !@env.has_key?("provision.enabled")
        end

        def call(env)
          # Instantiate and prepare the provisioners. Preparation must happen here
          # so that shared folders and such can properly take effect.
          provisioners = enabled_provisioners
          provisioners.map { |p| p.prepare }

          @app.call(env)

          # Take prepared provisioners and run the provisioning
          provisioners.each do |instance|
            @env[:ui].info I18n.t("vagrant.actions.vm.provision.beginning", :provisioner => instance.class)
            instance.provision!
          end
        end

        def enabled_provisioners
          @env[:vm].config.vm.provisioners.map do |provisioner|
            provisioner.provisioner.new(@env, provisioner.config)
          end
        end
      end
    end
  end
end
