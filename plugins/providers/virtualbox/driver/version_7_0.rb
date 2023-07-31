# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "rexml"
require File.expand_path("../version_6_1", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 7.0.x
      class Version_7_0 < Version_6_1
        # VirtualBox version requirement for using host only networks
        # instead of host only interfaces
        HOSTONLY_NET_REQUIREMENT=Gem::Requirement.new(">= 7")
        # Prefix of name used for host only networks
        HOSTONLY_NAME_PREFIX="vagrantnet-vbox"
        DEFAULT_NETMASK="255.255.255.0"

        def initialize(uuid)
          super

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_7_0")
        end

        def read_bridged_interfaces
          ifaces = super
          return ifaces if !use_host_only_nets?

          # Get a list of all subnets which are in use for hostonly networks
          hostonly_ifaces = read_host_only_networks.map do |net|
            IPAddr.new(net[:lowerip]).mask(net[:networkmask])
          end

          # Prune any hostonly interfaces in the list
          ifaces.delete_if { |i|
            addr = begin
                     IPAddr.new(i[:ip]).mask(i[:netmask])
                   rescue IPAddr::Error => err
                     @logger.warn("skipping bridged interface due to parse error #{err} (#{i}) ")
                     nil
                   end
            addr.nil? ||
              hostonly_ifaces.include?(addr)
          }

          ifaces
        end

        def delete_unused_host_only_networks
          return super if !use_host_only_nets?

          # First get the list of existing host only network names
          network_names = read_host_only_networks.map { |net| net[:name] }
          # Prune the network names to only include ones we manage
          network_names.delete_if { |name| !name.start_with?(HOSTONLY_NAME_PREFIX) }

          @logger.debug("managed host only network names: #{network_names}")

          return if network_names.empty?

          # Next get the list of host only networks currently in use
          inuse_names = []
          execute("list", "vms", retryable: true).split("\n").each do |line|
            match = line.match(/^".+?"\s+\{(?<vmid>.+?)\}$/)
            next if match.nil?
            begin
              info = execute("showvminfo", match[:vmid].to_s, "--machinereadable", retryable: true)
              info.split("\n").each do |vmline|
                if vmline.start_with?("hostonly-network")
                  net_name = vmline.split("=", 2).last.to_s.gsub('"', "")
                  inuse_names << net_name
                end
              end
            rescue Vagrant::Errors::VBoxManageError => err
              raise if !err.extra_data[:stderr].include?("VBOX_E_OBJECT_NOT_FOUND")
            end
          end

          @logger.debug("currently in use network names: #{inuse_names}")

          # Now remove all the networks not in use
          (network_names - inuse_names).each do |name|
            execute("hostonlynet", "remove", "--name", name, retryable: true)
          end
        end

        def enable_adapters(adapters)
          return super if !use_host_only_nets?

          hostonly_adapters = adapters.find_all { |adapter| adapter[:hostonly] }
          other_adapters = adapters - hostonly_adapters
          super(other_adapters) if !other_adapters.empty?

          if !hostonly_adapters.empty?
            args = []
            hostonly_adapters.each do |adapter|
              args.concat(["--nic#{adapter[:adapter]}", "hostonlynet"])
              args.concat(["--host-only-net#{adapter[:adapter]}", adapter[:hostonly],
                           "--cableconnected#{adapter[:adapter]}", "on"])
            end

            execute("modifyvm", @uuid, *args, retryable: true)
          end
        end

        def create_host_only_network(options)
          # If we are not on macOS, just setup the hostonly interface
          return super if !use_host_only_nets?

          opts = {
            netmask: options.fetch(:netmask, DEFAULT_NETMASK),
          }

          if options[:type] == :dhcp
            opts[:lower] = options[:dhcp_lower]
            opts[:upper] = options[:dhcp_upper]
          else
            addr = IPAddr.new(options[:adapter_ip])
            opts[:upper] = opts[:lower] = addr.mask(opts[:netmask]).to_range.first.to_s
          end

          name_idx = read_host_only_networks.map { |hn|
            next if !hn[:name].start_with?(HOSTONLY_NAME_PREFIX)
            hn[:name].sub(HOSTONLY_NAME_PREFIX, "").to_i
          }.compact.max.to_i + 1
          opts[:name] = HOSTONLY_NAME_PREFIX + name_idx.to_s

          execute("hostonlynet", "add",
                  "--name", opts[:name],
                  "--netmask", opts[:netmask],
                  "--lower-ip", opts[:lower],
                  "--upper-ip", opts[:upper],
                  retryable: true)

          {
            name: opts[:name],
            ip: options[:adapter_ip],
            netmask: opts[:netmask],
          }
        end

        # Disabled when host only nets are in use
        def reconfig_host_only(options)
          return super if !use_host_only_nets?
        end

        # Disabled when host only nets are in use since
        # the host only nets will provide the dhcp server
        def remove_dhcp_server(*_, **_)
          super if !use_host_only_nets?
        end

        # Disabled when host only nets are in use since
        # the host only nets will provide the dhcp server
        def create_dhcp_server(*_, **_)
          super if !use_host_only_nets?
        end

        def read_host_only_interfaces
          return super if !use_host_only_nets?

          # When host only nets are in use, read them and
          # reformat the information to line up with how
          # the interfaces is structured
          read_host_only_networks.map do |net|
            addr = begin
                     IPAddr.new(net[:lowerip])
                   rescue IPAddr::Error => err
                     @logger.warn("invalid host only network lower IP encountered: #{err} (#{net})")
                     next
                   end
            # Address of the interface will be the lower bound of the range or
            # the first available address in the subnet
            if addr == addr.mask(net[:networkmask])
              addr = addr.succ
            end

            net[:netmask] = net[:networkmask]
            if addr.ipv4?
              net[:ip] = addr.to_s
              net[:ipv6] = ""
            else
              net[:ip] = ""
              net[:ipv6] = addr.to_s
              net[:ipv6_prefix] = net[:netmask]
            end

            net[:status] = net[:state] == "Enabled" ? "Up" : "Down"

            net
          end.compact
        end

        def read_network_interfaces
          return super if !use_host_only_nets?

          {}.tap do |nics|
            execute("showvminfo", @uuid, "--machinereadable", retryable: true).each_line do |line|
              if m = line.match(/nic(?<adapter>\d+)="(?<type>.+?)"$/)
                nics[m[:adapter].to_i] ||= {}
                if m[:type] == "hostonlynetwork"
                  nics[m[:adapter].to_i][:type] = :hostonly
                else
                  nics[m[:adapter].to_i][:type] = m[:type].to_sym
                end
              elsif m = line.match(/^bridgeadapter(?<adapter>\d+)="(?<network>.+?)"$/)
                nics[m[:adapter].to_i] ||= {}
                nics[m[:adapter].to_i][:bridge] = m[:network]
              elsif m = line.match(/^hostonly-network(?<adapter>\d+)="(?<network>.+?)"$/)
                nics[m[:adapter].to_i] ||= {}
                nics[m[:adapter].to_i][:hostonly] = m[:network]
              end
            end
          end
        end

        # Generate list of host only networks
        def read_host_only_networks
          networks = []
          current = nil
          execute("list", "hostonlynets", retryable: true).split("\n").each do |line|
            line.chomp!
            next if line.empty?
            key, value = line.split(":", 2).map(&:strip)
            key = key.downcase
            if key == "name"
              networks.push(current) if !current.nil?
              current = Vagrant::Util::HashWithIndifferentAccess.new
            end
            current[key] = value
          end
          networks.push(current) if !current.nil?

          networks
        end

        # The initial VirtualBox 7.0 release has an issue with displaying port
        # forward information. When a single port forward is defined, the forwarding
        # information can be found in the `showvminfo` output. Once more than a
        # single port forward is defined, no forwarding information is provided
        # in the `showvminfo` output. To work around this we grab the VM configuration
        # file from the `showvminfo` output and extract the port forward information
        # from there instead.
        def read_forwarded_ports(uuid=nil, active_only=false)
          # Only use this override for the 7.0.0 release.
          return super if get_version.to_s != "7.0.0"

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
            networks = REXML::XPath.each(doc.root, "Machine/Hardware/Network/Adapter")
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

        private

        # Returns if hostonlynets are enabled on the current
        # host platform
        #
        # @return [Boolean]
        def use_host_only_nets?
          Vagrant::Util::Platform.darwin? &&
            HOSTONLY_NET_REQUIREMENT.satisfied_by?(get_version)
        end

        # VirtualBox version in use
        #
        # @return [Gem::Version]
        def get_version
          return @version if @version
          @version = Gem::Version.new(Meta.new.version)
        end
      end
    end
  end
end
