module Vagrant
  module Action
    module VM
      class CheckBox
        def initialize(app, env)
          @app = app
        end

        def call(env)
          box_name = env[:vm].config.vm.box
          raise Errors::BoxNotSpecified if !box_name

          if !env[:box_collection].find(box_name)
            box_url = env[:vm].config.vm.box_url
            raise Errors::BoxSpecifiedDoesntExist, :name => box_name if !box_url

            # Add the box then reload the box collection so that it becomes
            # aware of it.
            env[:ui].info I18n.t("vagrant.actions.vm.check_box.not_found", :name => box_name)
            env[:box_collection].add(box_name, box_url)
            env[:box_collection].reload!

            # Reload the configuration for all our VMs, since this box
            # may be used for other VMs.
            # TODO: This doesn't work properly
            env[:vm].env.vms.each do |name, vm|
              vm.env.reload_config!
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
