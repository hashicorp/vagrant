module Vagrant
  module Action
    module VM
      class Customize
        def initialize(app, env)
          @app = app
        end

        def call(env)
          customizations = env[:vm].config.vm.customizations
          if !customizations.empty?
            env[:ui].info I18n.t("vagrant.actions.vm.customize.running")

            # Execute each customization command.
            customizations.each do |command|
              processed_command = command.collect do |arg|
                arg = env[:vm].uuid if arg == :id
                arg
              end

              result = env[:vm].driver.execute_command(processed_command)
              if result.exit_code != 0
                raise Errors::VMCustomizationFailed, {
                  :command => processed_command.inspect,
                  :error   => result.stderr
                }
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
