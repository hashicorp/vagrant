module VagrantPlugins
  module GuestSmartos
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval
      # This sets the command to use to execute items as a superuser. sudo is default
      attr_accessor :suexec_cmd
      attr_accessor :device

      def initialize
        @halt_timeout = UNSET_VALUE
        @halt_check_interval = UNSET_VALUE
        @suexec_cmd = 'pfexec'
        @device = "e1000g"
      end

      def finalize!
        if @halt_timeout != UNSET_VALUE
          puts "smartos.halt_timeout is deprecated and will be removed in Vagrant 1.7"
        end
        if @halt_check_interval != UNSET_VALUE
          puts "smartos.halt_check_interval is deprecated and will be removed in Vagrant 1.7"
        end
      end
    end
  end
end
