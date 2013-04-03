module VagrantPlugins
  module Kernel_V2
    class DownloaderConfig < Vagrant.plugin("2", :config)
      attr_accessor :insecure

      def initialize
        super

        @insecure = UNSET_VALUE
      end

      def finalize!
        @insecure = false if @insecure == UNSET_VALUE
      end
    end
  end
end
