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
            try
            {
              $computer = Get-WmiObject -Class Win32_ComputerSystem
              $computer.rename("#{name}")
                 
              Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" 
              Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" 
              
              New-PSDrive -name HKU -PSProvider "Registry" -Root "HKEY_USERS"
              
              Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername" -name "Computername" -value "#{name}"
              Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -name "Computername" -value "#{name}"
              Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" -value "#{name}"
              Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" -value  "#{name}"
              Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "AltDefaultDomainName" -value "#{name}"
              Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultDomainName" -value "#{name}"
              Set-ItemProperty -path "HKCU:\Volatile Environment" -name "LOGONSERVER" -value "#{name}"
              [Environment]::SetEnvironmentVariable("COMPUTERNAME", "#{name}", "User")
              
              exit 0
            }
            catch
            {
              exit -1
            }
          EOH

          machine.communicate.execute(
            script,
            error_class: Errors::RenameComputerFailed,
            error_key: :rename_computer_failed)

          # Don't continue until the machine has shutdown and rebooted
          sleep(sleep_timeout)
        end
      end
    end
  end
end
