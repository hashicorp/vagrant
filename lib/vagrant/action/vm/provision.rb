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

          if !env.error? && provisioning_enabled?
            @env.logger.info "Beginning provisioning process..."
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
            return @env.error!(:provisioner_invalid_class) unless @provisioner.is_a?(Provisioners::Base)
          elsif provisioner.is_a?(Symbol)
            # We have a few hard coded provisioners for built-ins
            mapping = {
              :chef_solo    => Provisioners::ChefSolo,
              :chef_server  => Provisioners::ChefServer
            }

            provisioner_klass = mapping[provisioner]
            return @env.error!(:provisioner_unknown_type, :provisioner => provisioner.to_s) if provisioner_klass.nil?
            @provisioner = provisioner_klass.new(@env)
          end

          @env.logger.info "Provisioning enabled with #{@provisioner.class}"
          @provisioner.prepare
          @provisioner
        end
      end
    end
  end
end
