module Vagrant
  class Action
    module VM
      class Provision
        attr_reader :provisioners

        def initialize(app, env)
          @app = app
          @env = env
          @env["provision.enabled"] = true if !@env.has_key?("provision.enabled")
          @provisioners = []

          load_provisioners if provisioning_enabled?
        end

        def call(env)
          @app.call(env)

          @provisioners.each do |instance|
            @env.ui.info I18n.t("vagrant.actions.vm.provision.beginning", :provisioner => instance.class)
            instance.provision!
          end
        end

        def provisioning_enabled?
          !@env["config"].vm.provisioners.empty? && @env["provision.enabled"]
        end

        def load_provisioners
          @env["config"].vm.provisioners.each do |provisioner|
            @env.ui.info I18n.t("vagrant.actions.vm.provision.enabled", :provisioner => provisioner.shortcut)

            instance = provisioner.provisioner.new(@env)
            instance.prepare
            @provisioners << instance
          end
        end
      end
    end
  end
end
