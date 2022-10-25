require "rexml"
require File.expand_path("../version_6_1", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 7.0.x
      class Version_7_0 < Version_6_1
        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_7_0")
        end

        # The initial VirtualBox 7.0 release has an issue with displaying port
        # forward information. When a single port forward is defined, the forwarding
        # information can be found in the `showvminfo` output. Once more than a
        # single port forward is defined, no forwarding information is provided
        # in the `showvminfo` output. To work around this we grab the VM configuration
        # file from the `showvminfo` output and extract the port forward information
        # from there instead.
        def read_forwarded_ports(uuid=nil, active_only=false)
          @version ||= Meta.new.version

          # Only use this override for the 7.0.0 release. If it is still broken
          # on the 7.0.1 release we can modify the version check.
          return super if @version != "7.0.0"

          uuid ||= @uuid

          @logger.debug("read_forward_ports: uuid=#{uuid} active_only=#{active_only}")

          results = []

          info = execute("showvminfo", uuid, "--machinereadable", retryable: true)
          result = info.match(/CfgFile="(?<path>.+?)"/)
          if result.nil?
            raise Vagrant::Errors::VirtualBoxConfigNotFound,
                  uuid: uuid
          end

          File.open(result[:path], "r") do |f|
            doc = REXML::Document.new(f)
            networks = REXML::XPath.each(doc.root, "//Adapter")
            networks.each do |net|
              REXML::XPath.each(doc.root, net.xpath + "/NAT/Forwarding") do |fwd|
                # Result Array values:
                # [NIC Slot, Name, Host Port, Guest Port, Host IP]
                result = [
                  net.attribute("slot").value.to_i + 1,
                  fwd.attribute("name")&.value.to_s,
                  fwd.attribute("hostport")&.value.to_i,
                  fwd.attribute("guestport")&.value.to_i,
                  fwd.attribute("hostip")&.value.to_s
                ]
                @logger.debug(" - #{result.inspect}")
                results << result
              end
            end
          end

          results
        end
        
        # The initial VirtualBox 7.0 release with depreciation to Host Only Adapter.
        # Converting to Host Only Network
        def create_host_only_network(options)
          # Create the interface
          execute("hostonlynets", "create", retryable: true) =~ /^Interface '(.+?)' was successfully created$/
          name = $1.to_s

          # Get the IP so we can determine v4 vs v6
          ip = IPAddr.new(options[:adapter_ip])

          # Configure
          if ip.ipv4?
            execute("hostonlynets", "ipconfig", name,
                    "--ip", options[:adapter_ip],
                    "--netmask", options[:netmask],
                    retryable: true)
          elsif ip.ipv6?
            execute("hostonlynets", "ipconfig", name,
                    "--ipv6", options[:adapter_ip],
                    "--netmasklengthv6", options[:netmask].to_s,
                    retryable: true)
          else
            raise "BUG: Unknown IP type: #{ip.inspect}"
          end

          # Return the details
          return {
            name: name,
            ip:   options[:adapter_ip],
            netmask: options[:netmask],
            dhcp: nil
          }
        end
        
        def delete_unused_host_only_networks
          networks = []
          execute("list", "hostonlynets", retryable: true).split("\n").each do |line|
            networks << $1.to_s if line =~ /^Name:\s+(.+?)$/
          end

          execute("list", "vms", retryable: true).split("\n").each do |line|
            if line =~ /^".+?"\s+\{(.+?)\}$/
              begin
                info = execute("showvminfo", $1.to_s, "--machinereadable", retryable: true)
                info.split("\n").each do |inner_line|
                  if inner_line =~ /^hostonlynetwork\d+="(.+?)"$/
                    networks.delete($1.to_s)
                  end
                end
              rescue Vagrant::Errors::VBoxManageError => e
                raise if !e.extra_data[:stderr].include?("VBOX_E_OBJECT_NOT_FOUND")

                # VirtualBox could not find the vm. It may have been deleted
                # by another process after we called 'vboxmanage list vms'? Ignore this error.
              end
            end
          end

          networks.each do |name|
            # First try to remove any DHCP servers attached. We use `raw` because
            # it is okay if this fails. It usually means that a DHCP server was
            # never attached.
            raw("dhcpserver", "remove", "--ifname", name)

            # Delete the actual host only network interface.
            execute("hostonlynets", "remove", name, retryable: true)
          end
        end
        
        def read_host_only_interfaces
          execute("list", "hostonlynets", retryable: true).split("\n\n").collect do |block|
            info = {}

            block.split("\n").each do |line|
              if line =~ /^Name:\s+(.+?)$/
                info[:name] = $1.to_s
              elsif line =~ /^IPAddress:\s+(.+?)$/
                info[:ip] = $1.to_s
              elsif line =~ /^NetworkMask:\s+(.+?)$/
                info[:netmask] = $1.to_s
              elsif line =~ /^IPV6Address:\s+(.+?)$/
                info[:ipv6] = $1.to_s.strip
              elsif line =~ /^IPV6NetworkMaskPrefixLength:\s+(.+?)$/
                info[:ipv6_prefix] = $1.to_s.strip
              elsif line =~ /^Status:\s+(.+?)$/
                info[:status] = $1.to_s
              end
            end

            info
          end
        end
        
        def reconfig_host_only(interface)
          execute("hostonlynets", "ipconfig", interface[:name],
                  "--ipv6", interface[:ipv6], retryable: true)
        end
        
        def verify!
          # This command sometimes fails if kernel drivers aren't properly loaded
          # so we just run the command and verify that it succeeded.
          execute("list", "hostonlynets", retryable: true)
        end
      end
    end
  end
end
