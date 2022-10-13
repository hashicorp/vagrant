require "vagrant"
require File.expand_path("../vm_trigger", __FILE__)

module VagrantPlugins
  module Kernel_V2
    class TriggerConfig < Vagrant.plugin("2", :config)
      # The TriggerConfig class is what gets called when a user
      # defines a new trigger in their Vagrantfile. The two entry points are
      # either `config.trigger.before` or `config.trigger.after`.

      def initialize
        @logger = Log4r::Logger.new("vagrant::config::trigger")

        # Internal State
        @_before_triggers = [] # An array of VagrantConfigTrigger objects
        @_after_triggers  = [] # An array of VagrantConfigTrigger objects
      end

      #-------------------------------------------------------------------
      # Trigger before/after functions
      #-------------------------------------------------------------------
      #
      # Commands are expected to be ether:
      #   - splat
      #     + config.trigger.before :up, :destroy, :halt do |trigger|....
      #   - array
      #     + config.trigger.before [:up, :destroy, :halt] do |trigger|....
      #
      # Config is expected to be given as a block, or the last parameter as a hash
      #
      #   - block
      #     + config.trigger.before :up, :destroy, :halt do |trigger|
      #         trigger.option = "option"
      #       end
      #   - hash
      #     + config.trigger.before :up, :destroy, :halt, options: "option"

      # Reads in and parses Vagrant command whitelist and settings for a defined
      # trigger
      #
      # @param [Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined before block
      def before(*command, &block)
        command.flatten!
        blk = block

        if command.last.is_a?(Hash)
          if block_given?
            extra_cfg = command.pop
          else
            # We were given a hash rather than a block,
            # so the last element should be the "config block"
            # and the rest are commands for the trigger
            blk = command.pop
          end
        elsif !block_given?
          raise Vagrant::Errors::TriggersNoBlockGiven,
            command: command
        end

        command.each do |cmd|
          trigger = create_trigger(cmd, blk, extra_cfg)
          @_before_triggers << trigger
        end
      end

      # Reads in and parses Vagrant command whitelist and settings for a defined
      # trigger
      #
      # @param [Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def after(*command, &block)
        command.flatten!
        blk = block

        if command.last.is_a?(Hash)
          if block_given?
            extra_cfg = command.pop
          else
            # We were given a hash rather than a block,
            # so the last element should be the "config block"
            # and the rest are commands for the trigger
            blk = command.pop
          end
        elsif !block_given?
          raise Vagrant::Errors::TriggersNoBlockGiven,
            command: command
        end

        command.each do |cmd|
          trigger = create_trigger(cmd, blk, extra_cfg)
          @_after_triggers << trigger
        end
      end

      #-------------------------------------------------------------------
      # Internal methods, don't call these.
      #-------------------------------------------------------------------

      # Creates a new trigger config. If a block is given, parse that block
      # by calling it with the created trigger. Otherwise set the options if it's
      # a hash.
      #
      # @param [Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined config block
      # @param [Hash] extra_cfg Extra configurations for a block defined trigger (Optional)
      # @return [VagrantConfigTrigger]
      def create_trigger(command, block, extra_cfg=nil)
        trigger = VagrantConfigTrigger.new(command)
        if block.is_a?(Hash)
          trigger.set_options(block)
        else
          block.call(trigger, VagrantConfigTrigger)
          trigger.set_options(extra_cfg) if extra_cfg
        end
        return trigger
      end

      def merge(other)
        super.tap do |result|
          new_before_triggers = []
          new_after_triggers = []
          other_defined_before_triggers = other.instance_variable_get(:@_before_triggers)
          other_defined_after_triggers = other.instance_variable_get(:@_after_triggers)

          @_before_triggers.each do |bt|
            other_bft = other_defined_before_triggers.find { |o| bt.id == o.id }
            if other_bft
              # Override, take it
              other_bft = bt.merge(other_bft)

              # Preserve order, always
              bt = other_bft
              other_defined_before_triggers.delete(other_bft)
            end

            new_before_triggers << bt.dup
          end

          other_defined_before_triggers.each do |obt|
            new_before_triggers << obt.dup
          end
          result.instance_variable_set(:@_before_triggers, new_before_triggers)

          @_after_triggers.each do |at|
            other_aft = other_defined_after_triggers.find { |o| at.id == o.id }
            if other_aft
              # Override, take it
              other_aft = at.merge(other_aft)

              # Preserve order, always
              at = other_aft
              other_defined_after_triggers.delete(other_aft)
            end

            new_after_triggers << at.dup
          end

          other_defined_after_triggers.each do |oat|
            new_after_triggers << oat.dup
          end
          result.instance_variable_set(:@_after_triggers, new_after_triggers)
        end
      end

      # Iterates over all defined triggers and finalizes their config objects
      def finalize!
        if !@_before_triggers.empty?
          @_before_triggers.map { |t| t.finalize! }
        end

        if !@_after_triggers.empty?
          @_after_triggers.map { |t| t.finalize! }
        end
      end

      # Validate Trigger Arrays
      def validate(machine)
        errors = _detected_errors
        @_before_triggers.each do |bt|
          error = bt.validate(machine)
          errors.concat error if !error.empty?
        end

        @_after_triggers.each do |at|
          error = at.validate(machine)
          errors.concat error if !error.empty?
        end

        {"trigger" => errors}
      end

      # return [Array]
      def before_triggers
        @_before_triggers
      end

      # return [Array]
      def after_triggers
        @_after_triggers
      end

      # The String representation of this Trigger.
      #
      # @return [String]
      def to_s
        "trigger"
      end
    end
  end
end
