require 'log4r'

require "vagrant/util/platform"

require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Driver for VirtualBox 5.0.x
      class Version_5_0 < Base
        def initialize(uuid)
          super()

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox_5_0")
          @uuid = uuid
        end

        # Controller-Port-Device looks like:
        # SATA Controller-ImageUUID-0-0 (sub out ImageUUID)
        # - Controller: SATA Controller
        # - Port: 0
        # - Device: 0
        #
        # @param [String] controller_name - name of storage controller to attach disk to
        # @param [String] port - port on device to attach disk to
        # @param [String] device - device on controller for disk
        # @param [String] type - type of disk to attach
        # @param [String] file - disk file path
        # @param [Hash]   opts -  additional options
        def attach_disk(controller_name, port, device, type, file, **opts)
          comment = "This disk is managed externally by Vagrant. Removing or adjusting settings could potentially cause issues with Vagrant."

          execute('storageattach', @uuid,
                  '--storagectl', controller_name,
                  '--port', port.to_s,
                  '--device', device.to_s,
                  '--type', type,
                  '--medium', file,
                  '--comment', comment)
        end

        def clear_forwarded_ports
          retryable(on: Vagrant::Errors::VBoxManageError, tries: 3, sleep: 1) do
            args = []
            read_forwarded_ports(@uuid).each do |nic, name, _, _|
              args.concat(["--natpf#{nic}", "delete", name])
            end

            execute("modifyvm", @uuid, *args) if !args.empty?
          end
        end

        def clear_shared_folders
          retryable(on: Vagrant::Errors::VBoxManageError, tries: 3, sleep: 1) do
            info = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
            info.split("\n").each do |line|
              if line =~ /^SharedFolderNameMachineMapping\d+="(.+?)"$/
                execute("sharedfolder", "remove", @uuid, "--name", $1.to_s)
              end
            end
          end
        end

        # @param [String] source
        # @param [String] destination
        # @param [String] disk_format
        def clone_disk(source, destination, disk_format, **opts)
          execute("clonemedium", source, destination, '--format', disk_format)
        end

        def clonevm(master_id, snapshot_name)
          machine_name = "temp_clone_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"
          args = ["--register", "--name", machine_name]
          if snapshot_name
            args += ["--snapshot", snapshot_name, "--options", "link"]
          end

          execute("clonevm", master_id, *args, retryable: true)
          return get_machine_id(machine_name)
        end

        # Removes a disk from the given virtual machine
        #
        # @param [String] disk_uuid or file path
        # @param [Hash]   opts -  additional options
        def close_medium(disk_uuid)
          execute("closemedium", disk_uuid, '--delete')
        end

        def create_dhcp_server(network, options)
          retryable(on: Vagrant::Errors::VBoxManageError, tries: 3, sleep: 1) do
            begin
              execute("dhcpserver", "add", "--ifname", network,
                      "--ip", options[:dhcp_ip],
                      "--netmask", options[:netmask],
                      "--lowerip", options[:dhcp_lower],
                      "--upperip", options[:dhcp_upper],
                      "--enable")
            rescue Vagrant::Errors::VBoxManageError => e
              return if e.extra_data[:stderr] == 'VBoxManage: error: DHCP server already exists'
              raise
            end
          end
        end

       # Creates a disk. Default format is VDI unless overridden
       #
       # @param [String] disk_file
       # @param [Integer] disk_size - size in bytes
       # @param [String] disk_format - format of disk, defaults to "VDI"
        # @param [Hash]  opts -  additional options
       def create_disk(disk_file, disk_size, disk_format="VDI", **opts)
         execute("createmedium", '--filename', disk_file, '--sizebyte', disk_size.to_i.to_s, '--format', disk_format)
       end


        def create_host_only_network(options)
          # Create the interface
          execute("hostonlyif", "create", retryable: true) =~ /^Interface '(.+?)' was successfully created$/
          name = $1.to_s

          # Get the IP so we can determine v4 vs v6
          ip = IPAddr.new(options[:adapter_ip])

          # Configure
          if ip.ipv4?
            execute("hostonlyif", "ipconfig", name,
                    "--ip", options[:adapter_ip],
                    "--netmask", options[:netmask],
                    retryable: true)
          elsif ip.ipv6?
            execute("hostonlyif", "ipconfig", name,
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

        def create_snapshot(machine_id, snapshot_name)
          execute("snapshot", machine_id, "take", snapshot_name, retryable: true)
        end

        def delete_snapshot(machine_id, snapshot_name)
          # Start with 0%
          last = 0
          total = ""
          yield 0 if block_given?

          # Snapshot and report the % progress
          execute("snapshot", machine_id, "delete", snapshot_name, retryable: true) do |type, data|
            if type == :stderr
              # Append the data so we can see the full view
              total << data.gsub("\r", "")

              # Break up the lines. We can't get the progress until we see an "OK"
              lines = total.split("\n")

              # The progress of the import will be in the last line. Do a greedy
              # regular expression to find what we're looking for.
              match = /.+(\d{2})%/.match(lines.last)
              if match
                current = match[1].to_i
                if current > last
                  last = current
                  yield current if block_given?
                end
              end
            end
          end
        end

        # Lists all attached harddisks from a given virtual machine. Additionally,
        # this method adds a new key "Disk Name" based on the disks file path from "Location"
        #
        # @return [Array] hdds An array of hashes of harddrive info for a guest
        def list_hdds
          hdds = []
          tmp_drive = {}
          execute('list', 'hdds', retryable: true).split("\n").each do |line|
            if line == "" # separator between disks
              hdds << tmp_drive
              tmp_drive = {}
              next
            end
            parts = line.partition(":")
            key = parts.first.strip
            value = parts.last.strip
            tmp_drive[key] = value

            if key == "Location"
              tmp_drive["Disk Name"] = File.basename(value, ".*")
            end
          end
          hdds << tmp_drive unless tmp_drive.empty?

          hdds
        end

        def list_snapshots(machine_id)
          output = execute(
            "snapshot", machine_id, "list", "--machinereadable",
            retryable: true)

          result = []
          output.split("\n").each do |line|
            if line =~ /^SnapshotName.*?="(.+?)"$/i
              result << $1.to_s
            end
          end

          result.sort
        rescue Vagrant::Errors::VBoxManageError => e
          d = e.extra_data
          return [] if d[:stderr].include?("does not have") || d[:stdout].include?("does not have")
          raise
        end

        # @param [String] controller_name - controller name to remove disk from
        # @param [String] port - port on device to attach disk to
        # @param [String] device - device on controller for disk
        def remove_disk(controller_name, port, device)
          execute('storageattach', @uuid,
                  '--storagectl', controller_name,
                  '--port', port.to_s,
                  '--device', device.to_s,
                  '--medium', "none")
        end

        # @param [String] disk_file
        # @param [Integer] disk_size in bytes
        # @param [Hash]   opts -  additional options
        def resize_disk(disk_file, disk_size, **opts)
          execute("modifymedium", disk_file, '--resizebyte', disk_size.to_i.to_s)
        end

        def restore_snapshot(machine_id, snapshot_name)
          # Start with 0%
          last = 0
          total = ""
          yield 0 if block_given?

          execute("snapshot", machine_id, "restore", snapshot_name, retryable: true) do |type, data|
            if type == :stderr
              # Append the data so we can see the full view
              total << data.gsub("\r", "")

              # Break up the lines. We can't get the progress until we see an "OK"
              lines = total.split("\n")

              # The progress of the import will be in the last line. Do a greedy
              # regular expression to find what we're looking for.
              match = /.+(\d{2})%/.match(lines.last)
              if match
                current = match[1].to_i
                if current > last
                  last = current
                  yield current if block_given?
                end
              end
            end
          end
        end

        def delete
          execute("unregistervm", @uuid, "--delete", retryable: true)
        end

        def delete_unused_host_only_networks
          networks = []
          execute("list", "hostonlyifs", retryable: true).split("\n").each do |line|
            networks << $1.to_s if line =~ /^Name:\s+(.+?)$/
          end

          execute("list", "vms", retryable: true).split("\n").each do |line|
            if line =~ /^".+?"\s+\{(.+?)\}$/
              begin
                info = execute("showvminfo", $1.to_s, "--machinereadable", retryable: true)
                info.split("\n").each do |inner_line|
                  if inner_line =~ /^hostonlyadapter\d+="(.+?)"$/
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
            execute("hostonlyif", "remove", name, retryable: true)
          end
        end

        def discard_saved_state
          execute("discardstate", @uuid, retryable: true)
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
                          adapter[:hostonly], "--cableconnected#{adapter[:adapter]}", "on"])
            end

            if adapter[:intnet]
              args.concat(["--intnet#{adapter[:adapter]}",
                          adapter[:intnet], "--cableconnected#{adapter[:adapter]}", "on"])
            end

            if adapter[:mac_address]
              args.concat(["--macaddress#{adapter[:adapter]}",
                          adapter[:mac_address]])
            end

            if adapter[:nic_type]
              args.concat(["--nictype#{adapter[:adapter]}", adapter[:nic_type].to_s])
            end
          end

          execute("modifyvm", @uuid, *args, retryable: true)
        end

        def execute_command(command)
          execute(*command)
        end

        def export(path)
          retryable(on: Vagrant::Errors::VBoxManageError, tries: 3, sleep: 1) do
            begin
              execute("export", @uuid, "--output", path.to_s)
            rescue Vagrant::Errors::VBoxManageError => e
              raise if !e.extra_data[:stderr].include?("VERR_E_FILE_ERROR")

              # If the file already exists we'll throw a custom error
              raise Vagrant::Errors::VirtualBoxFileExists,
                stderr: e.extra_data[:stderr]
            end
          end
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

          execute("modifyvm", @uuid, *args, retryable: true) if !args.empty?
        end

        def get_machine_id(machine_name)
          output = execute("list", "vms", retryable: true)
          match = /^"#{Regexp.escape(machine_name)}" \{(.+?)\}$/.match(output)
          return match[1].to_s if match
          nil
        end

        # Returns port and device for an attached disk given a disk uuid. Returns
        # empty hash if disk is not attachd to guest
        #
        # @param [String] disk_uuid - the UUID for the disk we are searching for
        # @return [Hash] disk_info - Contains a device and port number
        def get_port_and_device(disk_uuid)
          disk = {}

          storage_controllers = read_storage_controllers
          storage_controllers.each do |controller|
            controller.attachments.each do |attachment|
              if disk_uuid == attachment[:uuid]
                disk[:port] = attachment[:port]
                disk[:device] = attachment[:device]
                return disk
              end
            end
          end

          return disk
        end

        def halt
          execute("controlvm", @uuid, "poweroff", retryable: true)
        end

        def import(ovf)
          ovf = Vagrant::Util::Platform.windows_path(ovf)

          output = ""
          total = ""
          last  = 0

          # Dry-run the import to get the suggested name and path
          @logger.debug("Doing dry-run import to determine parallel-safe name...")
          output = execute("import", "-n", ovf)
          result = /Suggested VM name "(.+?)"/.match(output)
          if !result
            raise Vagrant::Errors::VirtualBoxNoName, output: output
          end
          suggested_name = result[1].to_s

          # Append millisecond plus a random to the path in case we're
          # importing the same box elsewhere.
          specified_name = "#{suggested_name}_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"
          @logger.debug("-- Parallel safe name: #{specified_name}")

          # Build the specified name param list
          name_params = [
            "--vsys", "0",
            "--vmname", specified_name,
          ]

          # Extract the disks list and build the disk target params
          disk_params = []
          disks = output.scan(/(\d+): Hard disk image: source image=.+, target path=(.+),/)
          disks.each do |unit_num, path|
            disk_params << "--vsys"
            disk_params << "0"
            disk_params << "--unit"
            disk_params << unit_num
            disk_params << "--disk"
            if Vagrant::Util::Platform.windows?
              # we use the block form of sub here to ensure that if the specified_name happens to end with a number (which is fairly likely) then
              # we won't end up having the character sequence of a \ followed by a number be interpreted as a back reference.  For example, if
              # specified_name were "abc123", then "\\abc123\\".reverse would be "\\321cba\\", and the \3 would be treated as a back reference by the sub
              disk_params << path.reverse.sub("\\#{suggested_name}\\".reverse) { "\\#{specified_name}\\".reverse }.reverse # Replace only last occurrence
            else
              disk_params << path.reverse.sub("/#{suggested_name}/".reverse, "/#{specified_name}/".reverse).reverse # Replace only last occurrence
            end
          end

          execute("import", ovf , *name_params, *disk_params, retryable: true) do |type, data|
            if type == :stdout
              # Keep track of the stdout so that we can get the VM name
              output << data
            elsif type == :stderr
              # Append the data so we can see the full view
              total << data.gsub("\r", "")

              # Break up the lines. We can't get the progress until we see an "OK"
              lines = total.split("\n")
              if lines.include?("OK.")
                # The progress of the import will be in the last line. Do a greedy
                # regular expression to find what we're looking for.
                match = /.+(\d{2})%/.match(lines.last)
                if match
                  current = match[1].to_i
                  if current > last
                    last = current
                    yield current if block_given?
                  end
                end
              end
            end
          end

          return get_machine_id(specified_name)
        end

        def max_network_adapters
          8
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
            current_nic = $1.to_i if line =~ /^nic(\d+)=".+?"$/

              # If we care about active VMs only, then we check the state
              # to verify the VM is running.
              if active_only && line =~ /^VMState="(.+?)"$/ && $1.to_s != "running"
                return []
              end

            # Parse out the forwarded port information
            # Forwarding(1)="172.22.8.201tcp32977,tcp,172.22.8.201,32977,,3777"
            # Forwarding(2)="tcp32978,tcp,,32978,,3777"
            if line =~ /^Forwarding.+?="(.+?),.+?,(.*?),(.+?),.*?,(.+?)"$/
              result = [current_nic, $1.to_s, $3.to_i, $4.to_i, $2]
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
              if line =~ /^Name:\s+(.+?)$/
                info[:name] = $1.to_s
              elsif line =~ /^IPAddress:\s+(.+?)$/
                info[:ip] = $1.to_s
              elsif line =~ /^NetworkMask:\s+(.+?)$/
                info[:netmask] = $1.to_s
              elsif line =~ /^Status:\s+(.+?)$/
                info[:status] = $1.to_s
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
          if output =~ /^Value: (.+?)$/
            # Split the version by _ since some distro versions modify it
            # to look like this: 4.1.2_ubuntu, and the distro part isn't
            # too important.
            value = $1.to_s
            return value.split("_").first
          end

          # If we can't get the guest additions version by guest property, try
          # to get it from the VM info itself.
          info = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
          info.split("\n").each do |line|
            return $1.to_s if line =~ /^GuestAdditionsVersion="(.+?)"$/
          end

          return nil
        end

        def read_guest_ip(adapter_number)
          ip = read_guest_property("/VirtualBox/GuestInfo/Net/#{adapter_number}/V4/IP")
          if ip.end_with?(".1")
            @logger.warn("VBoxManage guest property returned: #{ip}. Result resembles IP of DHCP server and is being ignored.")
            ip = nil
          end

          if !valid_ip_address?(ip)
            raise Vagrant::Errors::VirtualBoxGuestPropertyNotFound,
              guest_property: "/VirtualBox/GuestInfo/Net/#{adapter_number}/V4/IP"
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

        def read_mac_address
          info = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
          info.split("\n").each do |line|
            return $1.to_s if line =~ /^macaddress1="(.+?)"$/
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
            if line =~ /^Default machine folder:\s+(.+?)$/i
              return $1.to_s
            end
          end

          nil
        end

        def read_network_interfaces
          nics = {}
          info = execute("showvminfo", @uuid, "--machinereadable", retryable: true)
          info.split("\n").each do |line|
            if line =~ /^nic(\d+)="(.+?)"$/
              adapter = $1.to_i
              type    = $2.to_sym

              nics[adapter] ||= {}
              nics[adapter][:type] = type
            elsif line =~ /^hostonlyadapter(\d+)="(.+?)"$/
              adapter = $1.to_i
              network = $2.to_s

              nics[adapter] ||= {}
              nics[adapter][:hostonly] = network
            elsif line =~ /^bridgeadapter(\d+)="(.+?)"$/
              adapter = $1.to_i
              network = $2.to_s

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
          elsif output =~ /^VMState="(.+?)"$/
            return $1.to_sym
          end

          nil
        end

        def read_used_ports
          used_ports = Hash.new{|hash, key| hash[key] = Set.new}
          execute("list", "vms", retryable: true).split("\n").each do |line|
            if line =~ /^".+?" \{(.+?)\}$/
              uuid = $1.to_s

              # Ignore our own used ports
              next if uuid == @uuid

              begin
                read_forwarded_ports(uuid, true).each do |_, _, hostport, _, hostip|
                  hostip = '*' if hostip.nil? || hostip.empty?
                  used_ports[hostport].add?(hostip)
                end
              rescue Vagrant::Errors::VBoxManageError => e
                raise if !e.extra_data[:stderr].include?("VBOX_E_OBJECT_NOT_FOUND")

                # VirtualBox could not find the vm. It may have been deleted
                # by another process after we called 'vboxmanage list vms'? Ignore this error.
              end
            end
          end

          used_ports
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

        def reconfig_host_only(interface)
          execute("hostonlyif", "ipconfig", interface[:name],
                  "--ipv6", interface[:ipv6], retryable: true)
        end

        def remove_dhcp_server(network_name)
          execute("dhcpserver", "remove", "--netname", network_name, retryable: true)
        end

        def set_mac_address(mac)
          mac = "auto" if !mac
          execute("modifyvm", @uuid, "--macaddress1", mac, retryable: true)
        end

        def set_name(name)
          retryable(on: Vagrant::Errors::VBoxManageError, tries: 3, sleep: 1) do
            begin
              execute("modifyvm", @uuid, "--name", name)
            rescue Vagrant::Errors::VBoxManageError => e
              raise if !e.extra_data[:stderr].include?("VERR_ALREADY_EXISTS")

              # We got VERR_ALREADY_EXISTS. This means that we're renaming to
              # a VM name that already exists. Raise a custom error.
              raise Vagrant::Errors::VirtualBoxNameExists,
                stderr: e.extra_data[:stderr]
            end
          end
        end

        def share_folders(folders)
          is_solaris = begin
                         "SunOS" == read_guest_property("/VirtualBox/GuestInfo/OS/Product")
                       rescue
                         false
                       end
          folders.each do |folder|
            # NOTE: Guest additions on Solaris guests do not properly handle
            # UNC style paths so prevent conversion (See GH-7264)
            if is_solaris
              hostpath = folder[:hostpath]
            else
              hostpath = Vagrant::Util::Platform.windows_path(folder[:hostpath])
            end
            args = ["--name",
              folder[:name],
              "--hostpath",
              hostpath]
            args << "--transient" if folder.key?(:transient) && folder[:transient]

            args << "--automount" if folder.key?(:automount) && folder[:automount]

            if folder[:SharedFoldersEnableSymlinksCreate]
              # Enable symlinks on the shared folder
              execute("setextradata", @uuid, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/#{folder[:name]}", "1", retryable: true)
            end

            # Add the shared folder
            execute("sharedfolder", "add", @uuid, *args, retryable: true)
          end
        end

        # Returns information for a given disk
        #
        # @param [String] disk_type - can be "disk", "dvd", or "floppy"
        # @param [String] disk_uuid_or_file
        # @return [Hash] disk
        def show_medium_info(disk_type, disk_uuid_or_file)
          disk = {}
          execute('showmediuminfo', disk_type, disk_uuid_or_file, retryable: true).split("\n").each do |line|
            parts = line.partition(":")
            key = parts.first.strip
            value = parts.last.strip
            disk[key] = value

            if key == "Location"
              disk["Disk Name"] = File.basename(value, ".*")
            end
          end
          disk
        end

        def ssh_port(expected_port)
          @logger.debug("Searching for SSH port: #{expected_port.inspect}")

          # Look for the forwarded port. Valid based on the guest port, but will do
          # scoring based matching to determine best value when multiple results are
          # available.
          matches = read_forwarded_ports.map do |_, name, hostport, guestport, host_ip|
            next if guestport != expected_port
            match = [0, hostport]
            match[0] += 1 if name == "ssh"
            match[0] += 1 if name.downcase == "ssh"
            match[0] += 1 if host_ip == "127.0.0.1"
            match
          end.compact

          result = matches.sort_by(&:first).last

          result.last if result
        end

        def resume
          @logger.debug("Resuming paused VM...")
          execute("controlvm", @uuid, "resume")
        end

        def start(mode)
          command = ["startvm", @uuid, "--type", mode.to_s]
          retryable(on: Vagrant::Errors::VBoxManageError, tries: 3, sleep: 1) do
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
        end

        def suspend
          execute("controlvm", @uuid, "savestate", retryable: true)
        end

        def unshare_folders(names)
          names.each do |name|
            retryable(on: Vagrant::Errors::VBoxManageError, tries: 3, sleep: 1) do
              begin
                execute(
                  "sharedfolder", "remove", @uuid,
                  "--name", name,
                  "--transient")

                execute(
                  "setextradata", @uuid,
                  "VBoxInternal2/SharedFoldersEnableSymlinksCreate/#{name}")
              rescue Vagrant::Errors::VBoxManageError => e
                raise if !e.extra_data[:stderr].include?("VBOX_E_FILE_ERROR")
              end
            end
          end
        end

        def verify!
          # This command sometimes fails if kernel drivers aren't properly loaded
          # so we just run the command and verify that it succeeded.
          execute("list", "hostonlyifs", retryable: true)
        end

        def verify_image(path)
          r = raw("import", path.to_s, "--dry-run")
          return r.exit_code == 0
        end

        def vm_exists?(uuid)
          5.times do |i|
            result = raw("showvminfo", uuid)
            return true if result.exit_code == 0

            # If vboxmanage returned VBOX_E_OBJECT_NOT_FOUND,
            # then the vm truly does not exist. Any other error might be transient
            return false if result.stderr.include?("VBOX_E_OBJECT_NOT_FOUND")

            # Sleep a bit though to give VirtualBox time to fix itself
            sleep 2
          end

          # If we reach this point, it means that we consistently got the
          # failure, do a standard vboxmanage now. This will raise an
          # exception if it fails again.
          execute("showvminfo", uuid)
          return true
        end

        # @param [VagrantPlugins::VirtualboxProvider::Driver] driver
        # @param [String] defined_disk_path
        # @return [String] destination - The cloned disk
        def vmdk_to_vdi(defined_disk_path)
          source = defined_disk_path
          destination = File.join(File.dirname(source), File.basename(source, ".*")) + ".vdi"

          clone_disk(source, destination, 'VDI')

          destination
        end

        # @param [VagrantPlugins::VirtualboxProvider::Driver] driver
        # @param [String] defined_disk_path
        # @return [String] destination - The cloned disk
        def vdi_to_vmdk(defined_disk_path)
          source = defined_disk_path
          destination = File.join(File.dirname(source), File.basename(source, ".*")) + ".vmdk"

          clone_disk(source, destination, 'VMDK')

          destination
        end

        # Helper method to get a list of storage controllers added to the
        # current VM
        #
        # @return [VagrantPlugins::ProviderVirtualBox::Model::StorageControllerArray]
        def read_storage_controllers
          vm_info = show_vm_info
          count = vm_info.count { |key, value| key.match(/^storagecontrollername\d+$/) }
          all_disks = list_hdds

          storage_controllers = Model::StorageControllerArray.new

          (0..count - 1).each do |n|
            # basic controller metadata
            name = vm_info["storagecontrollername#{n}"]
            type = vm_info["storagecontrollertype#{n}"]
            maxportcount = vm_info["storagecontrollermaxportcount#{n}"].to_i

            # build attachments array
            attachments = []
            vm_info.each do |k, v|
              if /^#{name}-ImageUUID-(\d+)-(\d+)$/ =~ k
                port = $1.to_s
                device = $2.to_s
                uuid = v
                location = vm_info["#{name}-#{port}-#{device}"]

                extra_disk_data = all_disks.detect { |d| d["UUID"] == uuid }

                attachment = { port: port,
                               device: device,
                               uuid: uuid,
                               location: location }

                extra_disk_data&.each do |dk,dv|
                  # NOTE: We convert the keys from VirtualBox to symbols
                  # to be consistent with the other keys
                  attachment[dk.downcase.gsub(' ', '_').to_sym] = dv
                end

                attachments << attachment
              end
            end

            storage_controllers << Model::StorageController.new(name, type, maxportcount, attachments)
          end

          storage_controllers
        end

        protected

        def valid_ip_address?(ip)
          # Filter out invalid IP addresses
          # GH-4658 VirtualBox can report an IP address of 0.0.0.0 for FreeBSD guests.
          if ip == "0.0.0.0" || ip.nil?
            return false
          else
            return true
          end
        end
      end
    end
  end
end
