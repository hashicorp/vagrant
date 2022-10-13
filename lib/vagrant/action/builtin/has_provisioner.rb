module Vagrant
  module Action
    module Builtin
      # This middleware is used with Call to test if this machine
      # has available provisioners
      class HasProvisioner
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::has_provisioner")
        end

        def call(env)
          machine = env[:machine]

          if machine.provider.capability?(:has_communicator)
            has_communicator = machine.provider.capability(:has_communicator)
          else
            has_communicator = true
          end

          env[:skip] = []
          if !has_communicator
            machine.config.vm.provisioners.each do |p|
              if p.communicator_required
                env[:skip].push(p)
                @logger.info("Skipping running provisioner #{p.name || 'no name'}, type: #{p.type}")
                p.run = :never
              end
            end
          end
          @app.call(env)
        end
      end
    end
  end
end
