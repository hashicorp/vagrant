module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Customize
        def initialize(app, env, event)
          @app = app
          @event = event
        end

        def call(env)
          customizations = []
          env[:machine].provider_config.customizations.each do |event, command|
            if event == @event
              customizations << command
            end
          end

          if !customizations.empty?
            env[:ui].info I18n.t("vagrant.actions.vm.customize.running", event: @event)

            # Execute each customization command.
            customizations.each do |command|
              processed_command = command.collect do |arg|
                arg = env[:machine].id if arg == :id
                arg.to_s
              end

              begin
                env[:machine].provider.driver.execute_command(
                  processed_command + [retryable: true])
              rescue Vagrant::Errors::VBoxManageError => e
                raise Vagrant::Errors::VMCustomizationFailed, {
                  command: command,
                  error:   e.inspect
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
