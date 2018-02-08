module Vagrant
  module Util
    # Helper methods for inspecting guests to determine if specific services
    # or applications are installed and in use
    module GuestInspection
      # Linux specific inspection helpers
      module Linux

        ## systemd helpers

        # systemd is in use
        #
        # @return [Boolean]
        def systemd?(comm)
          comm.test("ps -o comm= 1 | grep systemd")
        end

        # systemd-networkd.service is in use
        #
        # @return [Boolean]
        def systemd_networkd?(comm)
          comm.test("sudo systemctl status systemd-networkd.service")
        end

        # systemd hostname set is via hostnamectl
        #
        # @return [Boolean]
        def hostnamectl?(comm)
          comm.test("hostnamectl")
        end

        ## netplan helpers

        # netplan is installed
        #
        # @return [Boolean]
        def netplan?(comm)
          comm.test("netplan -h")
        end

        ## nmcli helpers

        # nmcli is installed
        #
        # @return [Boolean]
        def nmcli?(comm)
          comm.test("nmcli")
        end

        # NetworkManager currently controls device
        #
        # @param comm [Communicator]
        # @param device_name [String]
        # @return [Boolean]
        def nm_controlled?(comm, device_name)
          comm.test("nmcli d show #{device_name}") &&
            !comm.test("nmcli d show #{device_name} | grep unmanaged")
        end

      end
    end
  end
end
