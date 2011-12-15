require 'log4r'

module Vagrant
  module Config
    class VMConfig < Base
      # Represents a single configured provisioner for a VM.
      class Provisioner
        attr_reader :shortcut
        attr_reader :provisioner
        attr_reader :config

        def initialize(shortcut, options=nil, &block)
          @logger = Log4r::Logger.new("vagrant::config::vm::provisioner")
          @logger.debug("Provisioner config: #{shortcut}")
          @shortcut = shortcut
          @provisioner = shortcut
          @provisioner = Vagrant.provisioners.get(shortcut) if shortcut.is_a?(Symbol)
          @config = nil

          @logger.info("Provisioner class: #{provisioner}")
          configure(options, &block) if @provisioner
        end

        # Configures the provisioner if it can (if it is valid).
        def configure(options=nil, &block)
          config_class = @provisioner.config_class
          return if !config_class

          @logger.debug("Configuring provisioner with: #{config_class}")
          @config = config_class.new
          @config.set_options(options) if options
          block.call(@config) if block
        end

        def validate(env, errors)
          if !provisioner
            # If we don't have a provisioner then the whole thing is invalid.
            errors.add(I18n.t("vagrant.config.vm.provisioner_not_found", :shortcut => shortcut))
            return
          end

          if !(provisioner <= Provisioners::Base)
            errors.add(I18n.t("vagrant.config.vm.provisioner_invalid_class", :shortcut => shortcut))
          end

          # Pass on validation to the provisioner config
          config.validate(env, errors) if config
        end
      end
    end
  end
end
