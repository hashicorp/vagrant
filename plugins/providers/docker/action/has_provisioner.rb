module VagrantPlugins
  module DockerProvider
    module Action
      # This middleware is used with Call to test if this machine
      # has available provisioners
      class HasProvisioner
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          env[:run] = []
          env[:skip] = []
          has_ssh = env[:machine].provider_config.has_ssh
          if has_ssh
            env[:run] = env[:machine].config.vm.provisioners
          else
            env[:machine].config.vm.provisioners.each do |p|
              if p.communicator_required
                env[:skip].push(p) 
              else
                env[:run].push(p)
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
