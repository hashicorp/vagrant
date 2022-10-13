require File.expand_path("../version_6_0", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 7.0.x
      class Version_7_0 < Version_6_1
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_7_0")
        end

        def read_dhcp_servers
          execute("list", "dhcpservers", retryable: true).split("\n\n").collect do |block|
            info = {}

            block.split("\n").each do |line|
              if network = line[/^NetworkName:\s+HostInterfaceNetworking-(.+?)$/, 1]
                info[:network]      = network
                info[:network_name] = "HostInterfaceNetworking-#{network}"
              elsif ip = line[/^Dhcpd IP:\s+(.+?)$/, 1]
                info[:ip] = ip
              elsif netmask = line[/^NetworkMask:\s+(.+?)$/, 1]
                info[:netmask] = netmask
              elsif lower = line[/^LowerIPAddress:\s+(.+?)$/, 1]
                info[:lower] = lower
              elsif upper = line[/^UpperIPAddress:\s+(.+?)$/, 1]
                info[:upper] = upper
              end
            end

            info
          end
        end
      end
    end
  end
end
