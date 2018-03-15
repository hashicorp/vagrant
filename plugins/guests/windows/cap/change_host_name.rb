module VagrantPlugins
  module GuestWindows
    module Cap
      module ChangeHostName

        def self.change_host_name(machine, name)
          change_host_name_and_wait(machine, name)
        end

        def self.change_host_name_and_wait(machine, name)
          # If the configured name matches the current name, then bail
          # We cannot use %ComputerName% because it truncates at 15 chars
          return if machine.communicate.test("if ([System.Net.Dns]::GetHostName() -eq '#{name}') { exit 0 } exit 1")
          
          # Rename and reboot host if rename succeeded
          script = <<-EOH
            $computer = Get-WmiObject -Class Win32_ComputerSystem
            $retval = $computer.rename("#{name}").returnvalue
            if ($retval -eq 0) {
              shutdown /r /t 5 /f /d p:4:1 /c "Vagrant Rename Computer"
            }
            exit $retval
          EOH

          machine.communicate.execute(
            script,
            error_class: Errors::RenameComputerFailed,
            error_key: :rename_computer_failed)

          # Don't continue until the machine has shutdown and rebooted
          machine.guest.capability(:wait_for_reboot)
        end
      end
    end
  end
end
