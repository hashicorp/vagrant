module VagrantPlugins
  module GuestWindows
    module Cap
      module ChangeHostName

        def self.change_host_name(machine, name)
          change_host_name_and_wait(machine, name, machine.config.vm.graceful_halt_timeout)
        end

        def self.change_host_name_and_wait(machine, name, sleep_timeout)
          # If the configured name matches the current name, then bail
          return if machine.communicate.test("if ($env:ComputerName -eq '#{name}') { exit 0 } exit 1")

          # Rename and then reboot in one step
          exit_code = machine.communicate.execute(
            "netdom renamecomputer \"$Env:COMPUTERNAME\" /NewName:#{name} /Force /Reboot:0",
            error_check: false)

          raise Errors::RenameComputerFailed if exit_code != 0

          # Don't continue until the machine has shutdown and rebooted
          sleep(sleep_timeout)
        end
      end
    end
  end
end
