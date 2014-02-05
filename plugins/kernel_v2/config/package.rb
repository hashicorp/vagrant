require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class PackageConfig < Vagrant.plugin("2", :config)
      attr_accessor :name

      def initialize
        @name = UNSET_VALUE
      end

      def finalize!
        @name = nil if @name == UNSET_VALUE
      end

      def to_s
        "Package"
      end
    end
  end
end
