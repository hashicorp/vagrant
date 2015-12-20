require "log4r"

require_relative "mixin_provisioners"

module Vagrant
  module Action
    module Builtin
      # This action will run the cleanup methods on provisioners and should
      # be used as part of any Destroy action.
      class ProvisionerCleanup
        include MixinProvisioners

        def initialize(app, env, place=nil)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::provision_cleanup")

          place ||= :after
          @place = place.to_sym
        end

        def call(env)
          do_cleanup(env) if @place == :before

          # Continue, we need the VM to be booted.
          @app.call(env)

          do_cleanup(env) if @place == :after
        end

        def do_cleanup(env)
          type_map = provisioner_type_map(env)

          # Ask the provisioners to modify the configuration if needed
          provisioner_instances(env).each do |p, _|
            name = type_map[p].to_s

            # Check if the subclass defined a cleanup method. The parent
            # provisioning class defines a `cleanup` method, so we cannot use
            # `respond_to?` here. Instead, we have to check if _this_ instance
            # defines a cleanup task.
            if p.public_methods(false).include?(:cleanup)
              env[:ui].info(I18n.t("vagrant.provisioner_cleanup",
                name: name,
              ))
              p.cleanup
            else
              @logger.debug("Skipping cleanup tasks for `#{name}' - not defined")
            end
          end
        end
      end
    end
  end
end
