require "log4r"

require_relative "mixin_provisioners"

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
        include MixinProvisioners

        def initialize(app, env)
          @app             = app
          @logger          = Log4r::Logger.new("vagrant::action::builtin::provision")
        end

        def call(env)
          @env = env

          # Check if we already provisioned, and if so, disable the rest
          enabled = true

          ignore_sentinel = true
          if env.has_key?(:provision_ignore_sentinel)
            ignore_sentinel = env[:provision_ignore_sentinel]
          end

          sentinel_path = nil
          if !ignore_sentinel
            @logger.info("Checking provisioner sentinel if we should run...")
            sentinel_path = env[:machine].data_dir.join("action_provision")
            if sentinel_path.file?
              @logger.info("Sentinel found! Not provisioning.")
              enabled = false
            end
          end

          # Store the value so that other actions can use it
          env[:provision_enabled] = enabled if !env.has_key?(:provision_enabled)

          # Ask the provisioners to modify the configuration if needed
          provisioner_instances(env).each do |p|
            p.configure(env[:machine].config)
          end

          # Continue, we need the VM to be booted.
          @app.call(env)

          # Write the sentinel if we have to
          if sentinel_path && !sentinel_path.file?
            @logger.info("Writing provisioning sentinel so we don't provision again")
            sentinel_path.open("w") do |f|
              f.write(Time.now.to_i.to_s)
            end
          end

          # Actually provision if we enabled it
          if env[:provision_enabled]
            type_map = provisioner_type_map(env)
            provisioner_instances(env).each do |p|
              type_name = type_map[p]
              next if env[:provision_types] && \
                !env[:provision_types].include?(type_name)

              env[:ui].info(I18n.t(
                "vagrant.actions.vm.provision.beginning",
                provisioner: type_name))

              env[:hook].call(:provisioner_run, env.merge(
                callable: method(:run_provisioner),
                provisioner: p,
                provisioner_name: type_name,
              ))
            end
          elsif !enabled
            env[:ui].info(I18n.t("vagrant.actions.vm.provision.disabled_by_sentinel"))
          end
        end

        # This is pulled out into a seperate method so that users can
        # subclass and implement custom behavior if they'd like to work around
        # this step.
        def run_provisioner(env)
          env[:provisioner].provision
        end
      end
    end
  end
end
