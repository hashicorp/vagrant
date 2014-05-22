require "log4r"

module VagrantPlugins
  module GuestWindows
    # Manages the remote Windows guest network.
    class GuestNetwork
      PS_GET_WSMAN_VER = '((test-wsman).productversion.split(" ") | select -last 1).split("\.")[0]'
      WQL_NET_ADAPTERS_V2 = 'SELECT * FROM Win32_NetworkAdapter WHERE MACAddress IS NOT NULL'

      def initialize(communicator)
        @logger       = Log4r::Logger.new("vagrant::windows::guestnetwork")
        @communicator = communicator
      end

      # Returns an array of all NICs on the guest. Each array entry is a
      # Hash of the NICs properties.
      #
      # @return [Array]
      def network_adapters
        wsman_version == 2? network_adapters_v2_winrm : network_adapters_v3_winrm
      end

      # Checks to see if the specified NIC is currently configured for DHCP.
      #
      # @return [Boolean]
      def is_dhcp_enabled(nic_index)
        cmd = <<-EOH
          if (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "Index=#{nic_index} and DHCPEnabled=True") {
            exit 0
          }
          exit 1
        EOH
        @communicator.test(cmd)
      end

      # Configures the specified interface for DHCP
      #
      # @param [Integer] The interface index.
      # @param [String] The unique name of the NIC, such as 'Local Area Connection'.
      def configure_dhcp_interface(nic_index, net_connection_id)
        @logger.info("Configuring NIC #{net_connection_id} for DHCP")
        if !is_dhcp_enabled(nic_index)
          netsh = "netsh interface ip set address \"#{net_connection_id}\" dhcp"
          @communicator.execute(netsh)
        end
      end

      # Configures the specified interface using a static address
      #
      # @param [Integer] The interface index.
      # @param [String] The unique name of the NIC, such as 'Local Area Connection'.
      # @param [String] The static IP address to assign to the specified NIC.
      # @param [String] The network mask to use with the static IP.
      def configure_static_interface(nic_index, net_connection_id, ip, netmask)
        @logger.info("Configuring NIC #{net_connection_id} using static ip #{ip}")
        #netsh interface ip set address "Local Area Connection 2" static 192.168.33.10 255.255.255.0
        netsh = "netsh interface ip set address \"#{net_connection_id}\" static #{ip} #{netmask}"
        @communicator.execute(netsh)
      end

      # Sets all networks on the guest to 'Work Network' mode. This is
      # to allow guest access from the host via a private IP on Win7
      # https://github.com/WinRb/vagrant-windows/issues/63
      def set_all_networks_to_work
        @logger.info("Setting all networks to 'Work Network'")
        command = File.read(File.expand_path("../scripts/set_work_network.ps1", __FILE__))
        @communicator.execute(command)
      end

      protected

      # Checks the WinRS version on the guest. Usually 2 on Windows 7/2008
      # and 3 on Windows 8/2012.
      #
      # @return [Integer]
      def wsman_version
        @logger.debug("querying WSMan version")
        version = ''
        @communicator.execute(PS_GET_WSMAN_VER) do |type, line|
          version = version + "#{line}" if type == :stdout && !line.nil?
        end
        @logger.debug("wsman version: #{version}")
        Integer(version)
      end

      # Returns an array of all NICs on the guest. Each array entry is a
      # Hash of the NICs properties. This method should only be used on
      # guests that have WinRS version 2.
      #
      # @return [Array]
      def network_adapters_v2_winrm
        @logger.debug("querying network adapters")

        # Get all NICs that have a MAC address
        # http://msdn.microsoft.com/en-us/library/windows/desktop/aa394216(v=vs.85).aspx
        adapters = @communicator.execute(WQL_NET_ADAPTERS_V2, { shell: :wql } )[:win32_network_adapter]
        @logger.debug("#{adapters.inspect}")
        return adapters
      end

      # Returns an array of all NICs on the guest. Each array entry is a
      # Hash of the NICs properties. This method should only be used on
      # guests that have WinRS version 3.
      #
      # This method is a workaround until the WinRM gem supports WinRS version 3.
      #
      # @return [Array]
      def network_adapters_v3_winrm
        command = File.read(File.expand_path("../scripts/winrs_v3_get_adapters.ps1", __FILE__))
        output = ""
        @communicator.execute(command) do |type, line|
          output = output + "#{line}" if type == :stdout && !line.nil?
        end

        adapters = []
        JSON.parse(output).each do |nic|
          adapters << nic.inject({}){ |memo,(k,v)| memo[k.to_sym] = v; memo }
        end

        @logger.debug("#{adapters.inspect}")
        return adapters
      end
    end
  end
end
