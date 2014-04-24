module VagrantPlugins
  module CommunicatorWinRM
    module CommandFilters
      # Converts a *nix 'grep' command to a PowerShell equivalent (none)
      class Grep

        def filter(command)
          # grep 'Fedora release [12][67890]' /etc/redhat-release
          # grep Funtoo /etc/gentoo-release
          # grep Gentoo /etc/gentoo-release

          # grep is often used to detect the guest type in Vagrant, so don't bother running
          # to speed up OS detection
          ''
        end

        def accept?(command)
          command.start_with?('grep ')
        end
      end
    end
  end
end