module VagrantPlugins
  module GuestFreeBSD
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :device

      def initialize
        @device = "em"
      end
    end
  end
end