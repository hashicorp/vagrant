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

          # Check if we're even provisioning things.
          enabled = true

          # Check if we already provisioned, and if so, disable the rest
          ignore_sentinel = true
          ignore_sentinel = env[:provision_ignore_sentinel] if env.has_key?(:provision_ignore_sentinel)
          if !ignore_sentinel
            @logger.info("Checking provisioner sentinel if we should run...")
            sentinel = env[:machine].data_dir.join("action_provision")
            if sentinel.file?
              @logger.info("Sentinel found! Not provisioning.")
              enabled = false
            else
              @logger.info("Sentinel not found.")
              sentinel.open("w") do |f|
                f.write(Time.now.to_i.to_s)
              end
            end
          end

          # If we explicitly specified, take that value.
          enabled = env[:provision_enabled] if env.has_key?(:provision_enabled)

          # Ask the provisioners to modify the configuration if needed
          provisioner_instances.each do |p|
            p.configure(env[:machine].config)
          end

          # Continue, we need the VM to be booted.
          @app.call(env)

          # Actually provision if we enabled it
          if enabled
            provisioner_instances.each do |p|
              next if env[:provision_types] && \
                !env[:provision_types].include?(provisioner_type_map[p])

              run_provisioner(env, provisioner_type_map[p].to_s, p)
            end
          end
        end

        # This is pulled out into a seperate method so that users can
        # subclass and implement custom behavior if they'd like around
        # this step.
        def run_provisioner(env, name, p)
          env[:ui].info(I18n.t("vagrant.actions.vm.provision.beginning",
                               :provisioner => name))

          p.provision
        end
      end
    end
  end
end
