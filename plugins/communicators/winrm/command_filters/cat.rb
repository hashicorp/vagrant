module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters
      # Handles the special case of determining the guest OS using cat
      class Cat
        def filter(command)
          # cat /etc/release | grep -i OmniOS
          # cat /etc/redhat-release
          # cat /etc/issue | grep 'Core Linux'
          # cat /etc/release | grep -i SmartOS
          ''
        end

        def accept?(command)
          # cat works in PowerShell, however we don't want to run Guest
          # OS detection as this will fail on Windows because the lack of the
          # grep command
          command.start_with?('cat /etc/')
        end
      end
    end
  end
end
