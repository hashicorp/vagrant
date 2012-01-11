require "log4r"

module Vagrant
  module Action
    module VM
      class Provision
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::provision")
          @app = app

          env["provision.enabled"] = true if !env.has_key?("provision.enabled")
        end

        def call(env)
          @env = env

          provisioners = nil

          # We set this here so that even if this value is changed in the future,
          # it stays constant to what we expect here in this moment.
          enabled = env["provision.enabled"]
          if enabled
            # Instantiate and prepare the provisioners. Preparation must happen here
            # so that shared folders and such can properly take effect.
            provisioners = enabled_provisioners
            provisioners.map { |p| p.prepare }
          end

          @app.call(env)

          if enabled
            # Take prepared provisioners and run the provisioning
            provisioners.each do |instance|
              @env[:ui].info I18n.t("vagrant.actions.vm.provision.beginning",
                                    :provisioner => instance.class)
              instance.provision!
            end
          end
        end

        def enabled_provisioners
          enabled = []
          @env[:vm].config.vm.provisioners.each do |provisioner|
            if @env["provision.types"]
              # If we've specified types of provisioners to enable, then we
              # only use those provisioners, and skip any that we haven't
              # specified.
              if !@env["provision.types"].include?(provisioner.shortcut.to_s)
                @logger.debug("Skipping provisioner: #{provisioner.shortcut}")
                next
              end
            end

            enabled << provisioner.provisioner.new(@env, provisioner.config)
          end

          # Return the enable provisioners
          enabled
        end
      end
    end
  end
end
