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

          # Tracks whether we were configured to provision
          config_enabled = true
          config_enabled = env[:provision_enabled] if env.key?(:provision_enabled)

          # Check if we already provisioned, and if so, disable the rest
          provision_enabled = true

          ignore_sentinel = true
          if env.key?(:provision_ignore_sentinel)
            ignore_sentinel = env[:provision_ignore_sentinel]
          end
          if ignore_sentinel
            @logger.info("Ignoring sentinel check, forcing provision")
          end

          @logger.info("Checking provisioner sentinel file...")
          sentinel_path = env[:machine].data_dir.join("action_provision")
          update_sentinel = false
          if sentinel_path.file?
            # The sentinel file is in the format of "version:data" so that
            # we can remain backwards compatible with previous sentinels.
            # Versions so far:
            #
            #   Vagrant < 1.5.0: A timestamp. The weakness here was that
            #     if it wasn't cleaned up, it would incorrectly not provision
            #     new machines.
            #
            #   Vagrant >= 1.5.0: "1.5:ID", where ID is the machine ID.
            #     We compare both so we know whether it is a new machine.
            #
            contents = sentinel_path.read.chomp
            parts    = contents.split(":", 2)

            if parts.length == 1
              @logger.info("Old-style sentinel found! Not provisioning.")
              provision_enabled = false if !ignore_sentinel
              update_sentinel = true
            elsif parts[0] == "1.5" && parts[1] == env[:machine].id.to_s
              @logger.info("Sentinel found! Not provisioning.")
              provision_enabled = false if !ignore_sentinel
            else
              @logger.info("Sentinel found with another machine ID. Removing.")
              sentinel_path.unlink
            end
          end

          # Store the value so that other actions can use it
          env[:provision_enabled] = provision_enabled if !env.key?(:provision_enabled)

          # Ask the provisioners to modify the configuration if needed
          provisioner_instances(env).each do |p, _|
            p.configure(env[:machine].config)
          end

          # Continue, we need the VM to be booted.
          @app.call(env)

          # If we're configured to not provision, notify the user and stop
          if !config_enabled
            env[:ui].info(I18n.t("vagrant.actions.vm.provision.disabled_by_config"))
            return
          end

          # If we're not provisioning because of the sentinel, tell the user
          # but continue trying for the "always" provisioners
          if !provision_enabled
            env[:ui].info(I18n.t("vagrant.actions.vm.provision.disabled_by_sentinel"))
          end

          # Write the sentinel if we have to
          if update_sentinel || !sentinel_path.file?
            @logger.info("Writing provisioning sentinel so we don't provision again")
            sentinel_path.open("w") do |f|
              f.write("1.5:#{env[:machine].id}")
            end
          end

          type_map = provisioner_type_map(env)
          provisioner_instances(env).each do |p, options|
            type_name = type_map[p]

            if options[:run] == :never
              next if env[:provision_types].nil? || !env[:provision_types].include?(options[:name])
            else
              next if env[:provision_types] && \
                !env[:provision_types].include?(type_name) && \
                !env[:provision_types].include?(options[:name])

              # Don't run if sentinel is around and we're not always running
              next if !provision_enabled && options[:run] != :always
            end

            name = type_name
            if options[:name]
              name = "#{options[:name]} (#{type_name})"
            end

            env[:ui].info(I18n.t(
              "vagrant.actions.vm.provision.beginning",
              provisioner: name))

            env[:hook].call(:provisioner_run, env.merge(
              callable: method(:run_provisioner),
              provisioner: p,
              provisioner_name: type_name,
            ))
          end
        end

        # This is pulled out into a separate method so that users can
        # subclass and implement custom behavior if they'd like to work around
        # this step.
        def run_provisioner(env)
          env[:provisioner].provision
        end
      end
    end
  end
end
