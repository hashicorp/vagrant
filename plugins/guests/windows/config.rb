module VagrantPlugins
  module GuestWindows
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :halt_timeout
      attr_accessor :halt_check_interval
      attr_accessor :set_work_network

      def initialize
        @halt_timeout        = UNSET_VALUE
        @halt_check_interval = UNSET_VALUE
        @set_work_network    = UNSET_VALUE
      end

      def validate(machine)
        errors = []

        errors << "windows.halt_timeout cannot be nil."        if machine.config.windows.halt_timeout.nil?
        errors << "windows.halt_check_interval cannot be nil." if machine.config.windows.halt_check_interval.nil?

        errors << "windows.set_work_network cannot be nil." if machine.config.windows.set_work_network.nil?

        { "Windows Guest" => errors }
      end

      def finalize!
        @halt_timeout = 30       if @halt_timeout == UNSET_VALUE
        @halt_check_interval = 1 if @halt_check_interval == UNSET_VALUE
        @set_work_network = false if @set_work_network == UNSET_VALUE
      end
    end
  end
end
