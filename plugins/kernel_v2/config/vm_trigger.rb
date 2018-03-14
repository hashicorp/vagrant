require 'log4r'
require 'pry'

module VagrantPlugins
  module Kernel_V2
    # Represents a single configured provisioner for a VM.
    class VagrantConfigTrigger < Vagrant.plugin("2", :config)
      DEFAULT_ON_ERROR = :halt

      #-------------------------------------------------------------------
      # Config class for a given Trigger
      #-------------------------------------------------------------------

      # Internal unique name for this trigger
      #
      # Note: This is for internal use only.
      #
      # @return [String]
      attr_accessor :id

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
      # @return [Symbol, Array]
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

      def finalize!
        # Ensure all config options are set to nil if untouched by user
        @name = nil if @name == UNSET_VALUE
        @info = nil if @info == UNSET_VALUE
        @warn = nil if @warn == UNSET_VALUE
        @on_error = DEFAULT_ON_ERROR if @on_error == UNSET_VALUE
        @ignore = nil if @ignore == UNSET_VALUE
        @run = nil if @run == UNSET_VALUE
        @run_remote = nil if @run_remote == UNSET_VALUE
        @only_on = nil if @only_on == UNSET_VALUE

        # these values are expected to always be an Array internally,
        # but can be set as a single String or Symbol
        #
        # map to all be strings
        if !@only_on.nil?
          @only_on = Array(@only_on)
        end

        if !@ignore.nil?
          @ignore = @ignore.to_sym if @ignore.is_a?(String)
          @ignore = Array(@ignore)
        end

        # Convert @run and @run_remote to be a "Shell provisioner"
        if @run
        end

        if @run_remote
        end

      end

      def validate(machine)
        errors = _detected_errors

        commands = []
        Vagrant.plugin("2").manager.commands.each do |key,data|
          commands.push(key)
        end

        if !commands.include?(@command)
          machine.ui.warn(I18n.t("vagrant.config.triggers.bad_command_warning",
                                cmd: @command))
        end

        if !@run.nil?
          if !@run.is_a?(Hash)
            # Run must be a hash
            errors << I18n.t("vagrant.config.triggers.run.bad_type", cmd: @command)
          end

          if !@run.key?(:inline) && !@run.key?(:file)
            errors << I18n.t("vagrant.config.triggers.run.missing_context", cmd: @command)
          end
        end

        if !@run_remote.nil?
          if !@run_remote.is_a?(Hash)
            errors << I18n.t("vagrant.config.triggers.run_remote.bad_type", cmd: @command)
          end

          if !@run_remote.key?(:inline) && !@run_remote.key?(:file)
            errors << I18n.t("vagrant.config.triggers.run_remote.missing_context", cmd: @command)
          end
        end

        if !@name.nil? && !@name.is_a?(String)
          errors << I18n.t("vagrant.config.triggers.name_bad_type", cmd: @command)
        end

        if !@info.nil? && !@info.is_a?(String)
          errors << I18n.t("vagrant.config.triggers.info_bad_type", cmd: @command)
        end

        if !@warn.nil? && !@warn.is_a?(String)
          errors << I18n.t("vagrant.config.triggers.warn_bad_type", cmd: @command)
        end

        if @on_error != :halt
          if @on_error != :continue
            # must be :halt or :continue
            errors << I18n.t("vagrant.config.triggers.on_error_bad_type", cmd: @command)
          end
        end

        # @ignore validations?
        # @only_on validations?

        errors
      end

      # The String representation of this Trigger.
      #
      # @return [String]
      def to_s
        "Trigger Config"
      end
    end
  end
end
