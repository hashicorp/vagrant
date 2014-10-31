require "vagrant/util/counter"

module VagrantPlugins
  module Chef
    module Config
      class Base < Vagrant.plugin("2", :config)
        extend Vagrant::Util::Counter

        # The path to Chef's bin/ directory.
        # @return [String]
        attr_accessor :binary_path

        # Arbitrary environment variables to set before running the Chef
        # provisioner command.
        # @return [String]
        attr_accessor :binary_env

        # The Chef log level. See the Chef docs for acceptable values.
        # @return [String, Symbol]
        attr_accessor :log_level


        def initialize
          super

          @binary_path      = UNSET_VALUE
          @binary_env       = UNSET_VALUE
          @log_level        = UNSET_VALUE
        end

        def finalize!
          @binary_path      = nil     if @binary_path == UNSET_VALUE
          @binary_env       = nil     if @binary_env == UNSET_VALUE
          @log_level        = :info   if @log_level == UNSET_VALUE

          # Make sure the version is a symbol if it's not a boolean
          if @version.respond_to?(:to_sym)
            @version = @version.to_sym
          end

          # Make sure the log level is a symbol
          @log_level = @log_level.to_sym
        end

        # Like validate, but returns a list of errors to append.
        #
        # @return [Array<String>]
        def validate_base(machine)
          errors = _detected_errors

          if missing?(log_level)
            errors << I18n.t("vagrant.provisioners.chef.log_level_empty")
          end

          errors
        end

        # Determine if the given string is "missing" (blank)
        # @return [true, false]
        def missing?(obj)
          obj.to_s.strip.empty?
        end
      end
    end
  end
end
