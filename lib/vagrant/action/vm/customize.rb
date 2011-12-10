module Vagrant
  module Action
    module VM
      class Customize
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if !env[:vm].config.vm.proc_stack.empty?
            # Create the proc which runs all of our procs
            proc = lambda do |vm|
              env[:ui].info I18n.t("vagrant.actions.vm.customize.running")
              env[:vm].config.vm.run_procs!(vm)
            end

            # Add it to modify sequence
            env["vm.modify"].call(proc)
          end

          @app.call(env)
        end
      end
    end
  end
end
