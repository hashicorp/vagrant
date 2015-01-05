module VagrantPlugins
  module GuestSolaris
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval

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
          puts "solaris.halt_timeout is deprecated and will be removed in Vagrant 1.7"
        end

        if @halt_check_interval != UNSET_VALUE
          puts "solaris.halt_check_interval is deprecated and will be removed in Vagrant 1.7"
        end

        @suexec_cmd = "sudo" if @suexec_cmd == UNSET_VALUE
        @device     = "e1000g" if @device == UNSET_VALUE
      end
    end
  end
end
