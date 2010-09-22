module Vagrant
  class Action
    module VM
      class CheckBox
        def initialize(app, env)
          @app = app
        end

        def call(env)
          box_name = env["config"].vm.box
          raise Errors::BoxNotSpecified.new if !box_name

          if !env.env.boxes.find(box_name)
            box_url = env["config"].vm.box_url
            raise Errors::BoxSpecifiedDoesntExist.new(:name => box_name) if !box_url

            env.ui.info I18n.t("vagrant.actions.vm.check_box.not_found", :name => box_name)
            Vagrant::Box.add(env.env, box_name, box_url)
            env.env.load_box!
          end

          @app.call(env)
        end
      end
    end
  end
end
