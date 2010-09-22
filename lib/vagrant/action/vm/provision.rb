module Vagrant
  class Action
    module VM
      class Provision
        def initialize(app, env)
          @app = app
          @env = env

          load_provisioner if provisioning_enabled?
        end

        def call(env)
          @app.call(env)

          if provisioning_enabled?
            @env.ui.info I18n.t("vagrant.actions.vm.provision.beginning")
            @provisioner.provision!
          end
        end

        def provisioning_enabled?
          !@env["config"].vm.provisioner.nil?
        end

        def load_provisioner
          provisioner = @env["config"].vm.provisioner

          if provisioner.is_a?(Class)
            @provisioner = provisioner.new(@env)
            raise Errors::ProvisionInvalidClass.new if !@provisioner.is_a?(Provisioners::Base)
          elsif provisioner.is_a?(Symbol)
            # We have a few hard coded provisioners for built-ins
            mapping = {
              :chef_solo    => Provisioners::ChefSolo,
              :chef_server  => Provisioners::ChefServer
            }

            provisioner_klass = mapping[provisioner]
            raise Errors::ProvisionUnknownType.new(:provisioner => provisioner.to_s) if provisioner_klass.nil?
            @provisioner = provisioner_klass.new(@env)
          end

          @env.ui.info I18n.t("vagrant.actions.vm.provision.enabled", :provisioner => @provisioner.class.to_s)
          @provisioner.prepare
          @provisioner
        end
      end
    end
  end
end
