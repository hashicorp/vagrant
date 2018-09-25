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
        # @param [Vagrant::Plugin::V2::Communicator] comm Guest communicator
        # @return [Boolean]
        def systemd_networkd?(comm)
          comm.test("systemctl -q is-active systemd-networkd.service", sudo: true)
        end

        # Check if given service is controlled by systemd
        #
        # @param [Vagrant::Plugin::V2::Communicator] comm Guest communicator
        # @param [String] service_name Name of the service to check
        # @return [Boolean]
        def systemd_controlled?(comm, service_name)
          comm.test("systemctl -q is-active #{service_name}", sudo: true)
        end

        # systemd hostname set is via hostnamectl
        #
        # @param [Vagrant::Plugin::V2::Communicator] comm Guest communicator
        # @return [Boolean]
        def hostnamectl?(comm)
          comm.test("command -v hostnamectl")
        end

        ## netplan helpers

        # netplan is installed
        #
        # @param [Vagrant::Plugin::V2::Communicator] comm Guest communicator
        # @return [Boolean]
        def netplan?(comm)
          comm.test("command -v netplan")
        end

        ## nmcli helpers

        # nmcli is installed
        #
        # @param [Vagrant::Plugin::V2::Communicator] comm Guest communicator
        # @return [Boolean]
        def nmcli?(comm)
          comm.test("command -v nmcli")
        end

        # NetworkManager currently controls device
        #
        # @param [Vagrant::Plugin::V2::Communicator] comm Guest communicator
        # @param device_name [String]
        # @return [Boolean]
        def nm_controlled?(comm, device_name)
          comm.test("nmcli -t d show #{device_name}") &&
            !comm.test("nmcli -t d show #{device_name} | grep unmanaged")
        end

      end
    end
  end
end
