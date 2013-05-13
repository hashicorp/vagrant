require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class PackageConfig < Vagrant.plugin("1", :config)
      attr_accessor :name

      def initialize
        @name = UNSET_VALUE
      end

      def upgrade(new)
        new.package.name = @name if @name != UNSET_VALUE
      end
    end
  end
end
