# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>

module VagrantPlugins
  module GuestSolaris11
    class Config < Vagrant.plugin("2", :config)
      # This sets the command to use to execute items as a superuser. sudo is default
      attr_accessor :suexec_cmd
      attr_accessor :device

      def initialize
        @suexec_cmd = 'sudo'
        @device = "net"
      end
    end
  end
end
