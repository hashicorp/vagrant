require "log4r"

module VagrantPlugins
  module GuestWindows
    module Cap
      module ChangeHostName
        def self.change_host_name(machine, name)
          change_host_name_and_wait(machine, name, machine.config.vm.graceful_halt_timeout)
        end

        def self.change_host_name_and_wait(machine, name, sleep_timeout)
          # If the configured name matches the current name, then bail
          # We cannot use %ComputerName% because it truncates at 15 chars
          return if machine.communicate.test("if ([System.Net.Dns]::GetHostName() -eq '#{name}') { exit 0 } exit 1")

          # Rename and reboot host if rename succeeded
          script = <<-EOH
            $computer = Get-WmiObject -Class Win32_ComputerSystem
            $retval = $computer.rename("#{name}").returnvalue
            exit $retval
          EOH

          machine.communicate.execute(
            script,
            error_class: Errors::RenameComputerFailed,
            error_key: :rename_computer_failed)

          machine.guest.capability(:reboot)
        end
      end
    end
  end
end
