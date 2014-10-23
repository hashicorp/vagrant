require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class PushConfig < Vagrant.plugin("2", :config)
      VALID_OPTIONS = [:strategy].freeze

      attr_accessor :name

      def initialize
        # Internal state
        @__defined_pushes = {}
        @__finalized   = false
      end

      def finalize!
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
        validate_options!(options)

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

      # This returns the list of pushes defined in the Vagrantfile.
      #
      # @return [Array<Symbol>]
      def defined_pushes
        raise "Must finalize first!" if !@__finalized
        @__defined_pushes.keys
      end

      # This returns the compiled push-specific configuration for the given
      # provider.
      #
      # @param [#to_sym] name Name of the push
      def get_push(name)
        raise "Must finalize first!" if !@__finalized
        @__defined_pushes[name.to_sym]
      end

      private

      def validate_options!(options)
        extra_keys = VALID_OPTIONS - options.keys
        if !extra_keys.empty?
          raise "Invalid option(s): #{extra_keys.join(", ")}"
        end
      end
    end
  end
end
