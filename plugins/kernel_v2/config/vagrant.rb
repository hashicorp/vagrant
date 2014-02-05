require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class VagrantConfig < Vagrant.plugin("2", :config)
      attr_accessor :host

      def initialize
        @host = UNSET_VALUE
      end

      def finalize!
        @host = :detect if @host == UNSET_VALUE
        @host = @host.to_sym if @host
      end

      def to_s
        "Vagrant"
      end
    end
  end
end
