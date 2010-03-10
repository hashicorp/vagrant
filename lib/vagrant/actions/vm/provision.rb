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
            @provisioner = provisioner.new
            raise ActionException.new("Provisioners must be an instance of Vagrant::Provisioners::Base") unless @provisioner.is_a?(Provisioners::Base)
          elsif provisioner.is_a?(Symbol)
            # We have a few hard coded provisioners for built-ins
            mapping = {
              :chef_solo => Provisioners::ChefSolo
            }

            provisioner_klass = mapping[provisioner]
            raise ActionException.new("Unknown provisioner type: #{provisioner}") if provisioner_klass.nil?
            @provisioner = provisioner_klass.new
          end

          logger.info "Provisioning enabld with #{@provisioner.class}"
        end

        def execute!
          if provisioner
            logger.info "Beginning provisining process..."
            provisioner.provision!
          end
        end
      end
    end
  end
end
