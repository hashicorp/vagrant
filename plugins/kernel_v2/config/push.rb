require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class PushConfig < Vagrant.plugin("2", :config)
      VALID_OPTIONS = [:strategy].freeze

      attr_accessor :name

      def initialize
        @logger = Log4r::Logger.new("vagrant::config::push")

        # Internal state
        @__defined_pushes  = {}
        @__compiled_pushes = {}
        @__finalized       = false
      end

      def finalize!
        @logger.debug("finalizing")

        # Compile all the provider configurations
        @__defined_pushes.each do |name, tuples|
          # Capture the strategy so we can use it later. This will be used in
          # the block iteration for merging/overwriting
          strategy = name
          strategy = tuples[0][0] if tuples[0]

          # Find the configuration class for this push
          config_class = Vagrant.plugin("2").manager.push_configs[strategy]
          config_class ||= Vagrant::Config::V2::DummyConfig

          # Load it up
          config = config_class.new

          begin
            tuples.each do |s, b|
              # Update the strategy if it has changed, reseting the current
              # config object.
              if s != strategy
                @logger.warn("duplicate strategy defined, overwriting config")
                strategy = s
                config = config_class.new
              end

              # If we don't have any blocks, then ignore it
              next if b.nil?

              new_config = config_class.new
              b.call(new_config, Vagrant::Config::V2::DummyConfig.new)
              config = config.merge(new_config)
            end
          rescue Exception => e
            raise Vagrant::Errors::VagrantfileLoadError,
              path: "<push config: #{name}>",
              message: e.message
          end

          config.finalize!

          # Store it for retrieval later
          @__compiled_pushes[name] = [strategy, config]
        end

        @__finalized = true
      end

      # Define a new push in the Vagrantfile with the given name.
      #
      # @example
      #   vm.push.define "ftp"
      #
      # @example
      #   vm.push.define "ftp" do |s|
      #     s.host = "..."
      #   end
      #
      # @example
      #   vm.push.define "production", strategy: "docker" do |s|
      #     # ...
      #   end
      #
      # @param [#to_sym] name The name of the this strategy. By default, this
      #   is also the name of the strategy, but the `:strategy` key can be given
      #   to customize this behavior
      # @param [Hash] options The list of options
      #
      def define(name, **options, &block)
        name = name.to_sym
        strategy = options[:strategy] || name

        @__defined_pushes[name] ||= []
        @__defined_pushes[name] << [strategy.to_sym, block]
      end

      # The String representation of this Push.
      #
      # @return [String]
      def to_s
        "Push"
      end

      # Custom merge method
      def merge(other)
        super.tap do |result|
          other_pushes = other.instance_variable_get(:@__defined_pushes)
          new_pushes   = @__defined_pushes.dup

          other_pushes.each do |key, tuples|
            new_pushes[key] ||= []
            new_pushes[key] += tuples
          end

          result.instance_variable_set(:@__defined_pushes, new_pushes)
        end
      end

      # Validate all pushes
      def validate(machine)
        errors = { "push" => _detected_errors }

        __compiled_pushes.each do |_, push|
          config = push[1]
          push_errors = config.validate(machine)

          if push_errors
            errors = Vagrant::Config::V2::Util.merge_errors(errors, push_errors)
          end
        end

        errors
      end

      # This returns the list of compiled pushes as a hash by name.
      #
      # @return [Hash<Symbol, Array<Class, Object>>]
      def __compiled_pushes
        raise "Must finalize first!" if !@__finalized
        @__compiled_pushes.dup
      end
    end
  end
end
