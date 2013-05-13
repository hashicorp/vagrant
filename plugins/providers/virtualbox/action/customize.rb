module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Customize
        def initialize(app, env)
          @app = app
        end

        def call(env)
          customizations = env[:machine].provider_config.customizations
          if !customizations.empty?
            env[:ui].info I18n.t("vagrant.actions.vm.customize.running")

            # Execute each customization command.
            customizations.each do |command|
              processed_command = command.collect do |arg|
                arg = env[:machine].id if arg == :id
                arg.to_s
              end

              result = env[:machine].provider.driver.execute_command(processed_command)
              if result.exit_code != 0
                raise Vagrant::Errors::VMCustomizationFailed, {
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
