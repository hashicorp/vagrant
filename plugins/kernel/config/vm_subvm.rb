require "vagrant/util/stacked_proc_runner"

module VagrantPlugins
  module Kernel
    # Represents a single sub-VM in a multi-VM environment.
    class VagrantConfigSubVM
      include Vagrant::Util::StackedProcRunner

      attr_reader :options

      def initialize
        @options = {}
      end
    end
  end
end
