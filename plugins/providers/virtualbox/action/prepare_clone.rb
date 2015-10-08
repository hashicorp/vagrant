require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PrepareClone
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::prepare_clone")
        end

        def call(env)
          # We need to get the machine ID from this Vagrant environment
          clone_env = env[:machine].env.environment(
            env[:machine].config.vm.clone)
          raise Vagrant::Errors::CloneNotFound if !clone_env.root_path

          # Get the machine itself
          clone_machine = clone_env.machine(
            clone_env.primary_machine_name, env[:machine].provider_name)
          raise Vagrant::Errors::CloneMachineNotFound if !clone_machine.id

          # Set the ID of the master so we know what to clone from
          env[:clone_id] = clone_machine.id

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
