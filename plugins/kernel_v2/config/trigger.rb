require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class TriggerConfig < Vagrant.plugin("2", :config)
      DEFAULT_ON_ERROR = :halt

      # Name for the given Trigger. Defaults to nil.
      #
      # @return [String]
      attr_accessor :name

      # A string to print at the WARN level
      #
      # @return [String]
      attr_accessor :info

      # A string to print at the WARN level
      #
      # @return [String]
      attr_accessor :warn

      # Determines what how a Trigger should behave if it runs into an error.
      # Defaults to :halt, otherwise can only be set to :continue.
      #
      # @return [Symbol]
      attr_accessor :on_error

      # If set, will not run trigger for the configured Vagrant commands.
      #
      # @return [String, Array]
      attr_accessor :ignore


      # If set, will only run trigger for guests that match keys for this parameter.
      #
      # @return [String, Array]
      attr_accessor :only_on

      def initialize
        @logger = Log4r::Logger.new("vagrant::config::trigger")

        # Internal state
        @name = UNSET_VALUE
        @info = UNSET_VALUE
        @warn = UNSET_VALUE
        @on_error = UNSET_VALUE
        @ignore = UNSET_VALUE
        @only_on = UNSET_VALUE
      end

      # @param [Array, Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def before(**command, &block)
      end

      # @param [Array, Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def after(**command, &block)
      end

      # @param [Array, Symbol] command Vagrant command to create trigger on
      # @return [ActionHook] returns action hook?
      def parse_trigger_block(**command)
      end

      #-------------------------------------------------------------------
      # Internal methods, don't call these.
      #-------------------------------------------------------------------

      def finalize!
        @name = nil if @name == UNSET_VALUE
        @info = nil if @info == UNSET_VALUE
        @warn = nil if @warn == UNSET_VALUE
        @on_error = DEFAULT_ON_ERROR if @on_error == UNSET_VALUE
        @ignore = nil if @ignore == UNSET_VALUE
        @only_on = :halt if @only_on == UNSET_VALUE
      end

      # Validate Trigger settings
      def validate(machine)
      end

      # The String representation of this Trigger.
      #
      # @return [String]
      def to_s
        "Trigger"
      end
    end
  end
end
