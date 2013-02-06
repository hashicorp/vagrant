require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class VagrantConfig < Vagrant.plugin("1", :config)
      attr_accessor :dotfile_name
      attr_accessor :host

      def initialize
        @dotfile_name = UNSET_VALUE
        @host         = UNSET_VALUE
      end

      def finalize!
        @dotfile_name = nil if @dotfile_name == UNSET_VALUE
        @host = nil if @host == UNSET_VALUE
      end

      def upgrade(new)
        new.vagrant.host = @host if @host.nil?

        warnings = []
        if @dotfile_name
          warnings << "`config.vm.dotfile_name` has no effect anymore."
        end

        [warnings, []]
      end
    end
  end
end
