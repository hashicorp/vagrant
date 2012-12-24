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

      def upgrade(new)
        new.vagrant.dotfile_name = @dotfile_name if @dotfile_name != UNSET_VALUE
        new.vagrant.host = @host if @host != UNSET_VALUE
      end
    end
  end
end
