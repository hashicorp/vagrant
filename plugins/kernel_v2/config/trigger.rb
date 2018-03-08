require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class TriggerConfig < Vagrant.plugin("2", :config)

      attr_accessor :name

      def initialize
        @logger = Log4r::Logger.new("vagrant::config::trigger")

        # Internal state
        @name = UNSET_VALUE
      end

      # @param [Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def before(command, &block)
      end

      # @param [Symbol] command Vagrant command to create trigger on
      # @param [Block] block The defined after block
      def after(command, &block)
      end

      #-------------------------------------------------------------------
      # Internal methods, don't call these.
      #-------------------------------------------------------------------

      def finalize!
        @name = nil if @name == UNSET_VALUE
      end

      # Validate all pushes
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
