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
          comm.test("systemctl | grep '^-\.mount'")
        end

        # systemd hostname set is via hostnamectl
        #
        # @return [Boolean]
        def hostnamectl?(comm)
          comm.test("hostnamectl")
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
