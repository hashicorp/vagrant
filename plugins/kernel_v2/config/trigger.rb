require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class TriggerConfig < Vagrant.plugin("2", :config)
      DEFAULT_ON_ERROR = :halt

      # Name for the given Trigger. Defaults to nil.
      #
      # @return [String]
      attr_accessor :name

      # Internal unique name for this provisioner
      # Set to the given :name if exists, otherwise
      # it's set as a UUID.
      #
      # Note: This is for internal use only.
      #
      # @return [String]
      attr_reader :id

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
        @id = SecureRandom.uuid
        # Expected to store state like:
        # {@id=>{"command" => [Triggers],"command2"=>[Triggers]}}
        # finalize will take this data structure and construct action hooks
        # Does this make sense
        @_before_triggers = {} # A hash of all before triggers and their settings
        @_after_triggers  = {} # A hash of all after triggers and their settings

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

      # Reads in and parses Vagrant command whitelist and settings for a defined
      # trigger
      #
      # @param [Array, Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined before block
      def before(*command, &block)
        if block_given?
          puts "the command: #{command}"
          puts "the block: #{block}"
          command.each do |cmd|
            @_before_triggers[@id] = {cmd=>block}
          end
          puts @_before_triggers
        elsif command.last.is_a?(Hash)
          blck = command.pop
          command.each do |cmd|
            @_before_triggers[@id] = {cmd=>blck}
          end
        else
          # No config block given at all, validation step should throw error?
        end
        puts "The trigger: #{@_before_triggers}"
      end

      # @param [Array, Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def after(*command, &block)
        if block_given?
          store_after_trigger(command, block)
        elsif command.last.is_a?(Hash)
          blck = command.pop
          store_after_trigger(command, blck)
        else
          # No config block given at all, validation step should throw error?
        end
      end

      #-------------------------------------------------------------------
      # Internal methods, don't call these.
      #-------------------------------------------------------------------

      def store_before_trigger(*command, block)
        command.each do |cmd|
          @_before_triggers[@id] = {cmd=>block}
        end
      end

      def store_after_trigger(*command, block)
        command.each do |cmd|
          @_after_triggers[@id] = {cmd=>block}
        end
      end

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

      # Validate Trigger settings
      def validate(machine)
        errors = _detected_errors

        {"triggers" => errors}
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
