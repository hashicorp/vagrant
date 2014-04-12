module VagrantPlugins
  module GuestWindows
    module Cap
      class Reboot
        def self.wait_for_reboot(machine)
          # Technically it should be possible to make it work with SSH
          # too, but we don't yet.
          return if machine.config.vm.communicator != :winrm

          script  = File.expand_path("../../scripts/reboot_detect.ps1", __FILE__)
          script  = File.read(script)
          while machine.communicate.execute(script, error_check: false) != 0
            sleep 10
          end
        end
      end
    end
  end
end
