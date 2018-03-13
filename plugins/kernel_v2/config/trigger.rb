require "vagrant"
require 'pry'

require File.expand_path("../vm_trigger", __FILE__)

module VagrantPlugins
  module Kernel_V2
    class TriggerConfig < Vagrant.plugin("2", :config)

      def initialize
        @logger = Log4r::Logger.new("vagrant::config::trigger")

        # Internal State
        @_before_triggers = [] # An array of VagrantConfigTrigger objectrs
        @_after_triggers  = [] # An array of VagrantConfigTrigger objectrs
      end

      # Reads in and parses Vagrant command whitelist and settings for a defined
      # trigger
      #
      # @param [Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined before block
      def before(*command, &block)
        blk = block
        if !block_given? && command.last.is_a?(Hash)
          # We were given a hash rather than a block,
          # so the last element should be the "config block"
          # and the rest are commands for the trigger
          blk = command.pop
        else
          # No config block given at all, validation step should throw error?
        end

        command.each do |cmd|
          trigger = create_trigger(cmd, blk)
          @_before_triggers << trigger
        end
      end

      # Reads in and parses Vagrant command whitelist and settings for a defined
      # trigger
      #
      # @param [Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def after(*command, &block)
        blk = block
        if !block_given? && command.last.is_a?(Hash)
          # We were given a hash rather than a block,
          # so the last element should be the "config block"
          # and the rest are commands for the trigger
          blk = command.pop
        else
          # No config block given at all, validation step should throw error?
        end

        command.each do |cmd|
          trigger = create_trigger(cmd, blk)
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
      # @return [VagrantConfigTrigger]
      def create_trigger(command, block)
        trigger = VagrantConfigTrigger.new(command)
        if block.is_a?(Hash)
          trigger.set_options(block)
        else
          block.call(trigger, VagrantConfigTrigger)
        end
        trigger.finalize!
        return trigger
      end

      def finalize!
        # read through configured settings blocks and set their values
        # and then set up action hooks here?
        # for some reason not all triggers are showing up here
        #puts @_before_triggers if !@_before_triggers.empty?
        #puts @_after_triggers if !@_after_triggers.empty?
        if !@_before_triggers.empty?
          binding.pry
        end
      end

      # Validate Trigger settings
      def validate(machine)
        if !@_before_triggers.empty?
          binding.pry
        end

        errors = _detected_errors
        @_before_triggers.each do |bt|
          errors << bt.validate(machine)
        end

        @_after_triggers.each do |at|
          errors << at.validate(machine)
        end

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
