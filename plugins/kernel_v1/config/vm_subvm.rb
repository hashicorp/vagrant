require "vagrant/util/stacked_proc_runner"

module VagrantPlugins
  module Kernel_V1
    # Represents a single sub-VM in a multi-VM environment.
    class VagrantConfigSubVM
      include Vagrant::Util::StackedProcRunner

      attr_reader :options

      def initialize
        @options = {}
      end

      # This returns an array of the procs to configure this VM, with
      # the proper version pre-pended for the configuration loader.
      #
      # @return [Array]
      def config_procs
        proc_stack.map do |proc|
          ["1", proc]
        end
      end
    end
  end
end
