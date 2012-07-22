module Vagrant
  module Guest
    # Code adapted from vagrant-windows (by Chris McClimans <chris@hippiehacker.org>)
    class Windows < Base
      # A custom config class which will be made accessible via `config.windows`
      # Here for whenever it may be used.
      class WindowsConfig < Vagrant::Config::Base
        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval

        def initialize
          @halt_timeout = 15
          @halt_check_interval = 1
        end
      end

      def halt
        @vm.channel.execute("shutdown /s /t 1 /c \"Vagrant Halt\" /f /d p:4:1")

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while @vm.state != :poweroff
          count += 1

          return if count >= @vm.config.windows.halt_timeout
          sleep @vm.config.windows.halt_check_interval
        end
      end

    end
  end
end
