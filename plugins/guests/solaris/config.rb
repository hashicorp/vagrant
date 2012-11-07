module VagrantPlugins
  module GuestSolaris
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval
      # This sets the command to use to execute items as a superuser. sudo is default
      attr_accessor :suexec_cmd
      attr_accessor :device

      def initialize
        @halt_timeout = 30
        @halt_check_interval = 1
        @suexec_cmd = 'sudo'
        @device = "e1000g"
      end
    end
  end
end
