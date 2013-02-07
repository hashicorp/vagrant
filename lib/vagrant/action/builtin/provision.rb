require "log4r"

module Vagrant
  module Action
    module Builtin
      # This class will run the configured provisioners against the
      # machine.
      #
      # This action should be placed BEFORE the machine is booted so it
      # can do some setup, and then run again (on the return path) against
      # a running machine.
      class Provision
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::provision")
        end

        def call(env)
          # Check if we're even provisioning things.
          enabled = true
          enabled = env[:provision_enabled] if env.has_key?(:provision_enabled)

          # This keeps track of a mapping between provisioner and type
          type_map = {}

          # Get all the configured provisioners
          provisioners = env[:machine].config.vm.provisioners.map do |provisioner|
            # Instantiate the provisioner
            klass  = Vagrant.plugin("2").manager.provisioners[provisioner.name]
            result = klass.new(env[:machine], provisioner.config)

            # Store in the type map so that --provision-with works properly
            type_map[result] = provisioner.name

            # Return the result
            result
          end

          # Ask the provisioners to modify the configuration if needed
          provisioners.each do |p|
            p.configure(env[:machine].config)
          end

          # Continue, we need the VM to be booted.
          @app.call(env)

          # Actually provision if we enabled it
          if enabled
            provisioners.each do |p|
              next if env[:provision_types] && \
                !env[:provision_types].include?(type_map[p])

              run_provisioner(env, p)
            end
          end
        end

        # This is pulled out into a seperate method so that users can
        # subclass and implement custom behavior if they'd like around
        # this step.
        def run_provisioner(env, p)
          env[:ui].info(I18n.t("vagrant.actions.vm.provision.beginning",
                               :provisioner => p.class))

          p.provision
        end
      end
    end
  end
end
