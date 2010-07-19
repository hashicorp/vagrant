module Vagrant
  class Action
    module VM
      class Check
        def initialize(app, env)
          @app = app
        end
        
        def call(env)
          box_name = env["config"].vm.box

          env.logger.info "Checking if the box '#{box_name}' was already downloaded"
          
          box = Vagrant::Box.find(env.env , box_name)
          env.logger.info "The box #{box} were found"
          @app.call(env)
        end
      end
    end
  end
end
