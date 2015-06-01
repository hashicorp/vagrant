require 'log4r'

require "vagrant/util/platform"

require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 4.0.x
      class Version_4_0 < Base
        def initialize(uuid)
          super()

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_4_0")
          @uuid = uuid
        end

        def clear_forwarded_ports
          args = []
          read_forwarded_ports(@uuid).each do |nic, name, _, _|
            args.concat(["--natpf#{nic}", "delete", name])
          end

          execute("modifyvm", @uuid, *args) if !args.empty?
        end

        def clear_shared_folders
          info = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
          info.split("\n").each do |line|
            if name = line[/^SharedFolderNameMachineMapping\d+="(.+?)"$/, 1]
              execute("sharedfolder", "remove", @uuid, "--name", name)
            end
          end
        end

        def create_dhcp_server(network, options)
          execute("dhcpserver", "add", "--ifname", network,
                  "--ip", options[:dhcp_ip],
                  "--netmask", options[:netmask],
                  "--lowerip", options[:dhcp_lower],
                  "--upperip", options[:dhcp_upper],
                  "--enable")
        end

        def create_host_only_network(options)
          # Create the interface
          interface = execute("hostonlyif", "create")
          name = interface[/^Interface '(.+?)' was successfully created$/, 1]

          # Configure it
          execute("hostonlyif", "ipconfig", name,
                  "--ip", options[:adapter_ip],
                  "--netmask", options[:netmask])

          # Return the details
          return {
            name: name,
            ip:   options[:adapter_ip],
            netmask: options[:netmask],
            dhcp: nil
          }
        end

        def delete
          execute("unregistervm", @uuid, "--delete")
        end

        def delete_unused_host_only_networks
          networks = []
          execute("list", "hostonlyifs").split("\n").each do |line|
            if network_name = line[/^Name:\s+(.+?)$/, 1]
              networks << network_name
            end
          end

          execute("list", "vms").split("\n").each do |line|
            if vm_name = line[/^".+?"\s+\{(.+?)\}$/, 1]
              info = execute("showvminfo", vm_name, "--machinereadable", retryable: true)
              info.split("\n").each do |line|
                if network_name = line[/^hostonlyadapter\d+="(.+?)"$/, 1]
                  networks.delete(network_name)
                end
              end
            end
          end

          networks.each do |name|
            # First try to remove any DHCP servers attached. We use `raw` because
            # it is okay if this fails. It usually means that a DHCP server was
            # never attached.
            raw("dhcpserver", "remove", "--ifname", name)

            # Delete the actual host only network interface.
            execute("hostonlyif", "remove", name)
          end
        end

        def discard_saved_state
          execute("discardstate", @uuid)
        end

        def enable_adapters(adapters)
          args = []
          adapters.each do |adapter|
            args.concat(["--nic#{adapter[:adapter]}", adapter[:type].to_s])

            if adapter[:bridge]
              args.concat(["--bridgeadapter#{adapter[:adapter]}",
                          adapter[:bridge], "--cableconnected#{adapter[:adapter]}", "on"])
            end

            if adapter[:hostonly]
              args.concat(["--hostonlyadapter#{adapter[:adapter]}",
                          adapter[:hostonly]])
            end

            if adapter[:mac_address]
              args.concat(["--macaddress#{adapter[:adapter]}",
                          adapter[:mac_address]])
            end

            if adapter[:nic_type]
              args.concat(["--nictype#{adapter[:adapter]}", adapter[:nic_type].to_s])
            end
          end

          execute("modifyvm", @uuid, *args)
        end

        def execute_command(command)
          execute(*command)
        end

        def export(path)
          execute("export", @uuid, "--output", path.to_s)
        end

        def forward_ports(ports)
          args = []
          ports.each do |options|
            pf_builder = [options[:name],
              options[:protocol] || "tcp",
              options[:hostip] || "",
              options[:hostport],
              options[:guestip] || "",
              options[:guestport]]

            args.concat(["--natpf#{options[:adapter] || 1}",
                        pf_builder.join(",")])
          end

          execute("modifyvm", @uuid, *args) if !args.empty?
        end

        def halt
          execute("controlvm", @uuid, "poweroff")
        end

        def import(ovf)
          ovf = Vagrant::Util::Platform.cygwin_windows_path(ovf)

          output = ""
          total = ""
          last  = 0
          execute("import", ovf) do |type, data|
            if type == :stdout
              # Keep track of the stdout so that we can get the VM name
              output << data
            elsif type == :stderr
              # Append the data so we can see the full view
              total << data

              # Break up the lines. We can't get the progress until we see an "OK"
              lines = total.split("\n")
              if lines.include?("OK.")
                # The progress of the import will be in the last line. Do a greedy
                # regular expression to find what we're looking for.
                if current = lines.last[/.+(\d{2})%/, 1]
                  current = current.to_i
                  if current > last
                    last = current
                    yield current if block_given?
                  end
                end
              end
            end
          end

          # Find the name of the VM name
          name = output[/Suggested VM name "(.+?)"/, 1]
          if !name
            @logger.error("Couldn't find VM name in the output.")
            return nil
          end

          output = execute("list", "vms")
          if existing_vm = output[/^"#{Regexp.escape(name)}" \{(.+?)\}$/, 1]
            return existing_vm
          end

          nil
        end

        def read_forwarded_ports(uuid=nil, active_only=false)
          uuid ||= @uuid

          @logger.debug("read_forward_ports: uuid=#{uuid} active_only=#{active_only}")

          results = []
          current_nic = nil
          info = execute("showvminfo", uuid, "--machinereadable", retryable: true)
          info.split("\n").each do |line|
            # This is how we find the nic that a FP is attached to,
            # since this comes first.
            if nic = line[/^nic(\d+)=".+?"$/, 1]
              current_nic = nic.to_i
            end

            # If we care about active VMs only, then we check the state
            # to verify the VM is running.
            if active_only && (state = line[/^VMState="(.+?)"$/, 1] and state != "running")
              return []
            end

            # Parse out the forwarded port information
            if matcher = /^Forwarding.+?="(.+?),.+?,.*?,(.+?),.*?,(.+?)"$/.match(line)
              result = [current_nic, matcher[1], matcher[2].to_i, matcher[3].to_i]
              @logger.debug("  - #{result.inspect}")
              results << result
            end
          end

          results
        end

        def read_bridged_interfaces
          execute("list", "bridgedifs").split("\n\n").collect do |block|
            info = {}

            block.split("\n").each do |line|
              if name = line[/^Name:\s+(.+?)$/, 1]
                info[:name] = name
              elsif ip = line[/^IPAddress:\s+(.+?)$/, 1]
                info[:ip] = ip
              elsif netmask = line[/^NetworkMask:\s+(.+?)$/, 1]
                info[:netmask] = netmask
              elsif status = line[/^Status:\s+(.+?)$/, 1]
                info[:status] = status
              end
            end

            # Return the info to build up the results
            info
          end
        end

        def read_dhcp_servers
          execute("list", "dhcpservers", retryable: true).split("\n\n").collect do |block|
            info = {}

            block.split("\n").each do |line|
              if network = line[/^NetworkName:\s+HostInterfaceNetworking-(.+?)$/, 1]
                info[:network]      = network
                info[:network_name] = "HostInterfaceNetworking-#{network}"
              elsif ip = line[/^IP:\s+(.+?)$/, 1]
                info[:ip] = ip
              elsif netmask = line[/^NetworkMask:\s+(.+?)$/, 1]
                info[:netmask] = netmask
              elsif lower = line[/^lowerIPAddress:\s+(.+?)$/, 1]
                info[:lower] = lower
              elsif upper = line[/^upperIPAddress:\s+(.+?)$/, 1]
                info[:upper] = upper
              end
            end

            info
          end
        end

        def read_guest_additions_version
          output = execute("guestproperty", "get", @uuid, "/VirtualBox/GuestAdd/Version",
                           retryable: true)
          if value = output[/^Value: (.+?)$/, 1]
            # Split the version by _ since some distro versions modify it
            # to look like this: 4.1.2_ubuntu, and the distro part isn't
            # too important.
            return value.split("_").first
          end

          return nil
        end

        def read_guest_ip(adapter_number)
          ip = read_guest_property("/VirtualBox/GuestInfo/Net/#{adapter_number}/V4/IP")
          if !valid_ip_address?(ip)
            raise Vagrant::Errors::VirtualBoxGuestPropertyNotFound, guest_property: "/VirtualBox/GuestInfo/Net/#{adapter_number}/V4/IP"
          end

          return ip
        end

        def read_guest_property(property)
          output = execute("guestproperty", "get", @uuid, property)
          if output =~ /^Value: (.+?)$/
            $1.to_s
          else
            raise Vagrant::Errors::VirtualBoxGuestPropertyNotFound, guest_property: property
          end
        end

        def read_host_only_interfaces
          execute("list", "hostonlyifs", retryable: true).split("\n\n").collect do |block|
            info = {}

            block.split("\n").each do |line|
              if name = line[/^Name:\s+(.+?)$/, 1]
                info[:name] = name
              elsif ip = line[/^IPAddress:\s+(.+?)$/, 1]
                info[:ip] = ip
              elsif netmask = line[/^NetworkMask:\s+(.+?)$/, 1]
                info[:netmask] = netmask
              elsif status = line[/^Status:\s+(.+?)$/, 1]
                info[:status] = status
              end
            end

            info
          end
        end

        def read_mac_address
          info = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
          info.split("\n").each do |line|
            if mac = line[/^macaddress1="(.+?)"$/, 1]
              return mac
            end
          end

          nil
        end

        def read_mac_addresses
          macs = {}
          info = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
          info.split("\n").each do |line|
            if matcher = /^macaddress(\d+)="(.+?)"$/.match(line)
              adapter = matcher[1].to_i
              mac = matcher[2].to_s
              macs[adapter] = mac
            end
          end
          macs
        end

        def read_machine_folder
          execute("list", "systemproperties", retryable: true).split("\n").each do |line|
            if folder = line[/^Default machine folder:\s+(.+?)$/i, 1]
              return folder
            end
          end

          nil
        end

        def read_network_interfaces
          nics = {}
          info = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
          info.split("\n").each do |line|
            if matcher = /^nic(\d+)="(.+?)"$/.match(line)
              adapter = matcher[1].to_i
              type    = matcher[2].to_sym

              nics[adapter] ||= {}
              nics[adapter][:type] = type
            elsif matcher = /^hostonlyadapter(\d+)="(.+?)"$/.match(line)
              adapter = matcher[1].to_i
              network = matcher[2].to_s

              nics[adapter] ||= {}
              nics[adapter][:hostonly] = network
            elsif matcher = /^bridgeadapter(\d+)="(.+?)"$/.match(line)
              adapter = matcher[1].to_i
              network = matcher[2].to_s

              nics[adapter] ||= {}
              nics[adapter][:bridge] = network
            end
          end

          nics
        end

        def read_state
          output = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
          if output =~ /^name="<inaccessible>"$/
            return :inaccessible
          elsif state = output[/^VMState="(.+?)"$/, 1]
            return state.to_sym
          end

          nil
        end

        def read_used_ports
          ports = []
          execute("list", "vms", retryable: true).split("\n").each do |line|
            if uuid = line[/^".+?" \{(.+?)\}$/, 1]
              # Ignore our own used ports
              next if uuid == @uuid

              read_forwarded_ports(uuid, true).each do |_, _, hostport, _|
                ports << hostport
              end
            end
          end

          ports
        end

        def read_vms
          results = {}
          execute("list", "vms", retryable: true).split("\n").each do |line|
            if line =~ /^"(.+?)" \{(.+?)\}$/
              results[$1.to_s] = $2.to_s
            end
          end

          results
        end

        def remove_dhcp_server(network_name)
          execute("dhcpserver", "remove", "--netname", network_name)
        end

        def set_mac_address(mac)
          execute("modifyvm", @uuid, "--macaddress1", mac)
        end

        def set_name(name)
          execute("modifyvm", @uuid, "--name", name)
        end

        def share_folders(folders)
          folders.each do |folder|
            args = ["--name",
              folder[:name],
              "--hostpath",
              folder[:hostpath]]
            args << "--transient" if folder.key?(:transient) && folder[:transient]
            execute("sharedfolder", "add", @uuid, *args)
          end
        end

        def ssh_port(expected_port)
          @logger.debug("Searching for SSH port: #{expected_port.inspect}")

          # Look for the forwarded port only by comparing the guest port
          read_forwarded_ports.each do |_, _, hostport, guestport|
            return hostport if guestport == expected_port
          end

          nil
        end

        def resume
          @logger.debug("Resuming paused VM...")
          execute("controlvm", @uuid, "resume")
        end

        def start(mode)
          command = ["startvm", @uuid, "--type", mode.to_s]
          r = raw(*command)

          if r.exit_code == 0 || r.stdout =~ /VM ".+?" has been successfully started/
            # Some systems return an exit code 1 for some reason. For that
            # we depend on the output.
            return true
          end

          # If we reached this point then it didn't work out.
          raise Vagrant::Errors::VBoxManageError,
            command: command.inspect,
            stderr: r.stderr
        end

        def suspend
          execute("controlvm", @uuid, "savestate")
        end

        def unshare_folders(names)
          names.each do |name|
            begin
              execute(
                "sharedfolder", "remove", @uuid,
                "--name", name,
                "--transient")

            execute(
              "setextradata", @uuid,
              "VBoxInternal2/SharedFoldersEnableSymlinksCreate/#{name}")
            rescue Vagrant::Errors::VBoxManageError => e
              if e.extra_data[:stderr].include?("VBOX_E_FILE_ERROR")
                # The folder doesn't exist. ignore.
              else
                raise
              end
            end
          end
        end

        def valid_ip_address?(ip)
          # Filter out invalid IP addresses
          # GH-4658 VirtualBox can report an IP address of 0.0.0.0 for FreeBSD guests.
          if ip == "0.0.0.0"
            return false
          else
            return true
          end
        end

        def verify!
          # This command sometimes fails if kernel drivers aren't properly loaded
          # so we just run the command and verify that it succeeded.
          execute("list", "hostonlyifs")
        end

        def verify_image(path)
          r = raw("import", path.to_s, "--dry-run")
          return r.exit_code == 0
        end

        def vm_exists?(uuid)
          raw("showvminfo", uuid).exit_code == 0
        end
      end
    end
  end
end
