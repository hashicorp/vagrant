module VagrantPlugins
  module GuestLinux
    class Config < Vagrant::Config::Base
      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval

      def initialize
        @halt_timeout = 30
        @halt_check_interval = 1
      end
    end
  end
end
