require 'log4r'
require 'pry'

module VagrantPlugins
  module Kernel_V2
    # Represents a single configured provisioner for a VM.
    class VagrantConfigTrigger < Vagrant.plugin("2", :config)
      DEFAULT_ON_ERROR = :halt

      # Internal unique name for this trigger
      #
      # Note: This is for internal use only.
      #
      # @return [String]
      attr_reader :id

      # Name for the given Trigger. Defaults to nil.
      #
      # @return [String]
      attr_accessor :name

      # Command to fire the trigger on
      #
      # @return [Symbol]
      attr_reader :command

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

      def initialize(command)
        @logger = Log4r::Logger.new("vagrant::config::vm::trigger::config")
        #@logger.debug("Trigger defined: #{name}")

        @name = UNSET_VALUE
        @info = UNSET_VALUE
        @warn = UNSET_VALUE
        @on_error = UNSET_VALUE
        @ignore = UNSET_VALUE
        @only_on = UNSET_VALUE
        @run = UNSET_VALUE
        @run_remote = UNSET_VALUE

        # Internal options
        @id = SecureRandom.uuid
        @command = command.to_sym
      end

      #-------------------------------------------------------------------
      # Internal methods, don't call these.
      #-------------------------------------------------------------------

      def finalize!
        # Ensure all config options are set to nil if untouched by user
        @name = nil if @name == UNSET_VALUE
        @info = nil if @info == UNSET_VALUE
        @warn = nil if @warn == UNSET_VALUE
        @on_error = DEFAULT_ON_ERROR if @on_error == UNSET_VALUE
        @ignore = nil if @ignore == UNSET_VALUE
        @only_on = nil if @only_on == UNSET_VALUE
        @run = nil if @run == UNSET_VALUE
        @run_remote = nil if @run_remote == UNSET_VALUE
      end

      def validate(machine)
        binding.pry
        errors = _detected_errors
        # Validate that each config option has the right values and is the right type
        {"triggers" => errors}
      end
    end
  end
end
