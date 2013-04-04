module VagrantPlugins
  module GuestCygwin
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval
      # This sets the command to use to execute items as a superuser. sudo is default
      attr_accessor :suexec_cmd
      attr_accessor :device

      def initialize
        @halt_timeout = 30
        @halt_check_interval = 1
        @suexec_cmd = ""  # vagrant account is already administrator on windows
        @device = "Local Area Connection"  # I'm not sure if this is correct, but good enough for now.  Needs testing.
      end
    end
  end
end
