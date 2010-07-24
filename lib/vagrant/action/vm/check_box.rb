module Vagrant
  class Action
    module VM
      class CheckBox
        def initialize(app, env)
          @app = app
        end

        def call(env)
          box_name = env["config"].vm.box
          return env.error!(:box_not_specified) if !box_name

          if !Vagrant::Box.find(env.env , box_name)
            box_url = env["config"].vm.box_url
            return env.error!(:box_specified_doesnt_exist, :box_name => box_name) if !box_url

            env.logger.info "Box #{box_name} not found. Fetching box since URL specified..."
            Vagrant::Box.add(env.env, box_name, box_url)
            env.env.load_box!
          end

          @app.call(env)
        end
      end
    end
  end
end
