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

      # A local inline or file script to execute for the trigger
      #
      # @return [Hash]
      attr_accessor :run

      # A remote inline or file script to execute for the trigger
      #
      # @return [Hash]
      attr_accessor :run_remote

      def initialize
        @logger = Log4r::Logger.new("vagrant::config::trigger")

        # Internal state
        @_commands = []

        # Trigger config options
        @name = UNSET_VALUE
        @info = UNSET_VALUE
        @warn = UNSET_VALUE
        @on_error = UNSET_VALUE
        @ignore = UNSET_VALUE
        @only_on = UNSET_VALUE
        @run = UNSET_VALUE
        @run_remote = UNSET_VALUE
      end

      # @param [Array, Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def before(*command, &block)
      end

      # @param [Array, Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def after(*command, &block)
      end

      # Sets the internal Trigger state for which commands the Trigger will run on
      #
      # @param [Array, Symbol, Args] command Vagrant command to create trigger on
      def parse_command_whitelist(*command)
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
        @only_on = nil if @only_on == UNSET_VALUE
        @run = nil if @run == UNSET_VALUE
        @run_remote = nil if @run_remote == UNSET_VALUE
      end

      # Validate Trigger settings
      def validate(machine)
        if !@run.nil?
          # validate proper keys
          # WARN if invalid keys are used?
        end

        if !@run_remote.nil?
          # validate proper keys
          # WARN if invalid keys are used?
        end
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
