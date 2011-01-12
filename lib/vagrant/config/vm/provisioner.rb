module Vagrant
  class Config
    class VMConfig < Base
      # Represents a single configured provisioner for a VM.
      class Provisioner
        attr_reader :shortcut
        attr_reader :provisioner
        attr_reader :config

        def initialize(shortcut, options=nil, &block)
          @shortcut = shortcut
          @provisioner = Provisioners::Base.registered[shortcut]
          @config = nil

          configure(options, &block)
        end

        # Configures the provisioner if it can (if it is valid).
        def configure(options=nil, &block)
          # We assume that every provisioner has a `Config` class beneath
          # it for configuring.
          return if !defined?(@provisioner::Config)

          # Instantiate the config class and configure it
          @config = @provisioner::Config.new
          block.call(@config) if block

          # TODO: Deal with the options hash
        end

        def validate(errors)
          if !provisioner
            # If we don't have a provisioner then the whole thing is invalid.
            errors.add(I18n.t("vagrant.config.vm.provisioner_not_found", :shortcut => shortcut))
            return
          end

          if !(provisioner <= Provisioners::Base)
            errors.add(I18n.t("vagrant.config.vm.provisioner_invalid_class", :shortcut => shortcut))
          end

          # Pass on validation to the provisioner config
          config.validate(errors) if config
        end
      end
    end
  end
end
