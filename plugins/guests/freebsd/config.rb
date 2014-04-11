module VagrantPlugins
  module GuestFreeBSD
    class Config < Vagrant.plugin("2", :config)
      # The device prefix for network devices created by Vagrant.
      # This defaults to "em" but can be set for example to "vtnet"
      # for virtio devices and so on.
      #
      # @return [String]
      attr_accessor :device

      def initialize
        @device = UNSET_VALUE
      end

      def finalize!
        @device = "em" if @device == UNSET_VALUE
      end
    end
  end
end
