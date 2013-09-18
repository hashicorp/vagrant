require "log4r"

require_relative "mixin_provisioners"

module Vagrant
  module Action
    module Builtin
      # This action will run the cleanup methods on provisioners and should
      # be used as part of any Destroy action.
      class ProvisionerCleanup
        include MixinProvisioners

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::provision_cleanup")
        end

        def call(env)
          @env = env

          # Ask the provisioners to modify the configuration if needed
          provisioner_instances.each do |p|
            env[:ui].info(I18n.t(
              "vagrant.provisioner_cleanup",
              name: provisioner_type_map[p].to_s))
            p.cleanup
          end

          # Continue, we need the VM to be booted.
          @app.call(env)

          # Clean up sentinel files
          [ "action_provision",
            "action_set_name",
          ].each do |filename|
            @logger.info("Looking for provisioner sentinel #{filename}")
            sentinel = env[:machine].data_dir.join(filename)
            if sentinel.file?
              @logger.info("Sentinel found! Removing...")
              sentinel.delete
            end
          end
        end
      end
    end
  end
end
