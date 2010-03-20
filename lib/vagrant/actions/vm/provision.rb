module Vagrant
  module Actions
    module VM
      class Provision < Base
        attr_reader :provisioner

        def intialize(*args)
          super

          @provisioner = nil
        end

        def prepare
          provisioner = Vagrant.config.vm.provisioner

          if provisioner.nil?
            logger.info("Provisioning not enabled, ignoring this step")
            return
          end

          if provisioner.is_a?(Class)
            @provisioner = provisioner.new(@runner.env)
            raise ActionException.new(:provisioner_invalid_class) unless @provisioner.is_a?(Provisioners::Base)
          elsif provisioner.is_a?(Symbol)
            # We have a few hard coded provisioners for built-ins
            mapping = {
              :chef_solo    => Provisioners::ChefSolo,
              :chef_server  => Provisioners::ChefServer
            }

            provisioner_klass = mapping[provisioner]
            raise ActionException.new(:provisioner_unknown_type, :provisioner => provisioner.to_s) if provisioner_klass.nil?
            @provisioner = provisioner_klass.new(@runner.env)
          end

          logger.info "Provisioning enabled with #{@provisioner.class}"
          @provisioner.prepare
        end

        def execute!
          if provisioner
            logger.info "Beginning provisioning process..."
            provisioner.provision!
          end
        end
      end
    end
  end
end
