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

                if arg =~ /^disk(\d+)$/
                  disk_id = $1.to_i
                  disks = env[:machine].provider.driver.read_disks

                  if not disks or disk_id >= disks.size
                    raise Vagrant::Errors::VMCustomizationFailed, {
                      command: "Discovering UUID for the specified disk",
                      error:   "Disk with index #{disk_id} does not exist"
                    }
                  end

                  arg = disks[disk_id]
                end

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
