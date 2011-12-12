module Vagrant
  module Config
    class VMConfig < Base
      # Represents a single configured provisioner for a VM.
      class Provisioner
        attr_reader :top
        attr_reader :shortcut
        attr_reader :provisioner
        attr_reader :config

        def initialize(top, shortcut, options=nil, &block)
          @top = top
          @shortcut = shortcut
          @provisioner = shortcut
          @provisioner = Provisioners::Base.registered[shortcut] if shortcut.is_a?(Symbol)
          @config = nil

          configure(options, &block)
        end

        # Configures the provisioner if it can (if it is valid).
        def configure(options=nil, &block)
          # We don't want ancestors to be searched. This is the default in 1.8,
          # but not in 1.9, hence this hackery.
          const_args = ["Config"]
          const_args << false if RUBY_VERSION >= "1.9"

          # We assume that every provisioner has a `Config` class beneath
          # it for configuring.
          return if !@provisioner || !@provisioner.const_defined?(*const_args)

          # Instantiate the config class and configure it
          @config = @provisioner.const_get(*const_args).new
          @config.top = top
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
