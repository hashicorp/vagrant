module VagrantPlugins
  module GuestSolaris
    class Config < Vagrant.plugin("2", :config)
      # This sets the command to use to execute items as a superuser. sudo is default
      attr_accessor :suexec_cmd
      attr_accessor :device

      def initialize
        @suexec_cmd = 'sudo'
        @device = "e1000g"
      end
    end
  end
end
