# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>

module VagrantPlugins
  module GuestSolaris11
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval
      # This sets the command to use to execute items as a superuser. sudo is default
      attr_accessor :suexec_cmd
      attr_accessor :device

      def initialize
        @halt_timeout = UNSET_VALUE
        @halt_check_interval = UNSET_VALUE
        @suexec_cmd = UNSET_VALUE
        @device = UNSET_VALUE
      end

      def finalize!
        if @halt_timeout != UNSET_VALUE
          puts "solaris11.halt_timeout is deprecated and will be removed in Vagrant 1.7"
        end
        if @halt_check_interval != UNSET_VALUE
          puts "solaris11.halt_check_interval is deprecated and will be removed in Vagrant 1.7"
        end

        @suexec_cmd = "sudo" if @suexec_cmd == UNSET_VALUE
        @device     = "net" if @device == UNSET_VALUE
      end
    end
  end
end
