module Vagrant
  module Action
    module Builtin
      # This built-in middleware handles the `box_url` setting, downloading
      # the box if necessary. You should place this early in your middleware
      # sequence for a provider after configuration validation but before
      # you attempt to use any box.
      class HandleBoxUrl
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if !env[:machine].box
            # We can assume a box URL is set because the Vagrantfile
            # validation should do this for us. If not, though, we do
            # raise a terrible runtime error.
            box_name = env[:machine].config.vm.box
            box_url  = env[:machine].config.vm.box_url

            # Add the box then reload the box collection so that it becomes
            # aware of it.
            env[:ui].info I18n.t(
              "vagrant.actions.vm.check_box.not_found",
              :name => box_name,
              :provider => env[:machine].provider_name)
            env[:action_runner].run(Vagrant::Action.action_box_add, {
              :box_name     => box_name,
              :box_provider => env[:machine].provider_name,
              :box_url      => box_url
            })

            # Reload the environment and set the VM to be the new loaded VM.
            env[:machine] = env[:machine].env.machine(
              env[:machine].name, env[:machine].provider_name, true)
          end

          @app.call(env)
        end
      end
    end
  end
end
