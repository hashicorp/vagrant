require 'log4r'

module VagrantPlugins
  module Kernel
    # Represents a single configured provisioner for a VM.
    class VagrantConfigProvisioner
      attr_reader :shortcut
      attr_reader :provisioner
      attr_reader :config

      def initialize(shortcut, options=nil, &block)
        @logger = Log4r::Logger.new("vagrant::config::vm::provisioner")
        @logger.debug("Provisioner config: #{shortcut}")
        @shortcut = shortcut
        @provisioner = shortcut
        @config = nil

        # If the shorcut is a symbol, we look through the registered
        # plugins to see if any define a provisioner we want.
        if shortcut.is_a?(Symbol)
          Vagrant.plugin("1").registered.each do |plugin|
            if plugin.provisioner.has_key?(shortcut)
              @provisioner = plugin.provisioner[shortcut]
              break
            end
          end
        end

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

        if !(provisioner <= Vagrant::Provisioners::Base)
          errors.add(I18n.t("vagrant.config.vm.provisioner_invalid_class", :shortcut => shortcut))
        end

        # Pass on validation to the provisioner config
        config.validate(env, errors) if config
      end
    end
  end
end
