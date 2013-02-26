require 'log4r'

require 'vagrant/driver/virtualbox_base'
require 'vagrant/util/platform'

module Vagrant
  module Driver
    # Driver for VirtualBox 4.2.x
    class VirtualBox_4_2 < VirtualBoxBase
      def initialize(uuid)
        super()

        @logger = Log4r::Logger.new("vagrant::driver::virtualbox_4_2")
        @uuid = uuid

        # "Jank mode." VirtualBox 4.2.0 has a horrendous bug where
        # showvminfo with `--machinereadable` doesn't return proper output.
        # In this case, Vagrant works around it by using equally horrendous
        # regular expressions for the non-machine-readable output of
        # showvminfo. This, ladies and gentlemen, is jank mode.
        @jank_mode = false
        if Util::Platform.windows?
          if execute("--version").start_with?("4.2.0r")
            @logger.info("Windows with v4.2.0. Jank mode engage.")
            @jank_mode = true
          end
        end
      end

      def clear_forwarded_ports
        args = []
        read_forwarded_ports(@uuid).each do |nic, name, _, _|
          args.concat(["--natpf#{nic}", "delete", name])
        end

        execute("modifyvm", @uuid, *args) if !args.empty?
      end

      def clear_shared_folders
        return jank_clear_shared_folders if @jank_mode

        info = execute("showvminfo", @uuid, "--machinereadable", :retryable => true)
        info.split("\n").each do |line|
          if line =~ /^SharedFolderNameMachineMapping\d+="(.+?)"$/
            execute("sharedfolder", "remove", @uuid, "--name", $1.to_s)
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
        execute("hostonlyif", "create") =~ /^Interface '(.+?)' was successfully created$/
        name = $1.to_s

        # Configure it
        execute("hostonlyif", "ipconfig", name,
                "--ip", options[:adapter_ip],
                "--netmask", options[:netmask])

        # Return the details
        return {
          :name => name,
          :ip   => options[:adapter_ip],
          :netmask => options[:netmask],
          :dhcp => nil
        }
      end

      def delete
        execute("unregistervm", @uuid, "--delete")
      end

      def delete_unused_host_only_networks
        networks = []
        execute("list", "hostonlyifs").split("\n").each do |line|
          networks << $1.to_s if line =~ /^Name:\s+(.+?)$/
        end

        execute("list", "vms").split("\n").each do |line|
          if line =~ /^".+?"\s+\{(.+?)\}$/
            if @jank_mode
              adapters = jank_read_hostonly_adapters($1.to_s)
              adapters.each do |adapter|
                networks.delete(adapter)
              end
            else
              info = execute("showvminfo", $1.to_s, "--machinereadable", :retryable => true)
              info.split("\n").each do |info_line|
                if info_line =~ /^hostonlyadapter\d+="(.+?)"$/
                  networks.delete($1.to_s)
                end
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
                         adapter[:bridge]])
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
        raw(*command)
      end

      def export(path)
        # TODO: Progress
        execute("export", @uuid, "--output", path.to_s)
      end

      def forward_ports(ports)
        args = []
        ports.each do |options|
          pf_builder = [options[:name],
                        options[:protocol] || "tcp",
                        "",
                        options[:hostport],
                        "",
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
              if lines.last =~ /.+(\d{2})%/
                current = $1.to_i
                if current > last
                  last = current
                  yield current if block_given?
                end
              end
            end
          end
        end

        # Find the name of the VM name
        if output !~ /Suggested VM name "(.+?)"/
          @logger.error("Couldn't find VM name in the output.")
          return nil
        end

        name = $1.to_s

        output = execute("list", "vms")
        if output =~ /^"#{Regexp.escape(name)}" \{(.+?)\}$/
          return $1.to_s
        end

        nil
      end

      def read_forwarded_ports(uuid=nil, active_only=false)
        uuid ||= @uuid
        @logger.debug("read_forward_ports: uuid=#{uuid} active_only=#{active_only}")

        return jank_read_forwarded_ports(uuid, active_only) if @jank_mode

        results = []
        current_nic = nil
        info = execute("showvminfo", uuid, "--machinereadable", :retryable => true)
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
          if line =~ /^Forwarding.+?="(.+?),.+?,.*?,(.+?),.*?,(.+?)"$/
            result = [current_nic, $1.to_s, $2.to_i, $3.to_i]
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

      def read_guest_additions_version
        output = execute("guestproperty", "get", @uuid, "/VirtualBox/GuestAdd/Version",
                         :retryable => true)
        if output =~ /^Value: (.+?)$/
          # Split the version by _ since some distro versions modify it
          # to look like this: 4.1.2_ubuntu, and the distro part isn't
          # too important.
          value = $1.to_s
          return value.split("_").first
        end

        return nil
      end

      def read_host_only_interfaces
        dhcp = {}
        execute("list", "dhcpservers", :retryable => true).split("\n\n").each do |block|
          info = {}

          block.split("\n").each do |line|
            if line =~ /^NetworkName:\s+HostInterfaceNetworking-(.+?)$/
              info[:network] = $1.to_s
            elsif line =~ /^IP:\s+(.+?)$/
              info[:ip] = $1.to_s
            elsif line =~ /^lowerIPAddress:\s+(.+?)$/
              info[:lower] = $1.to_s
            elsif line =~ /^upperIPAddress:\s+(.+?)$/
              info[:upper] = $1.to_s
            end
          end

          # Set the DHCP info
          dhcp[info[:network]] = info
        end

        execute("list", "hostonlyifs", :retryable => true).split("\n\n").collect do |block|
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

          # Set the DHCP info if it exists
          info[:dhcp] = dhcp[info[:name]] if dhcp[info[:name]]

          info
        end
      end

      def read_mac_address
        return jank_read_mac_address if @jank_mode

        info = execute("showvminfo", @uuid, "--machinereadable", :retryable => true)
        info.split("\n").each do |line|
          return $1.to_s if line =~ /^macaddress1="(.+?)"$/
        end

        nil
      end

      def read_machine_folder
        execute("list", "systemproperties", :retryable => true).split("\n").each do |line|
          if line =~ /^Default machine folder:\s+(.+?)$/i
            return $1.to_s
          end
        end

        nil
      end

      def read_network_interfaces
        return jank_read_network_interfaces if @jank_mode

        nics = {}
        info = execute("showvminfo", @uuid, "--machinereadable", :retryable => true)
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
        return jank_read_state if @jank_mode

        output = execute("showvminfo", @uuid, "--machinereadable", :retryable => true)
        if output =~ /^name="<inaccessible>"$/
          return :inaccessible
        elsif output =~ /^VMState="(.+?)"$/
          return $1.to_sym
        end

        nil
      end

      def read_used_ports
        ports = []
        execute("list", "vms", :retryable => true).split("\n").each do |line|
          if line =~ /^".+?" \{(.+?)\}$/
            uuid = $1.to_s

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
        results = []
        execute("list", "vms", :retryable => true).split("\n").each do |line|
          if line =~ /^".+?" \{(.+?)\}$/
            results << $1.to_s
          end
        end

        results
      end

      def set_mac_address(mac)
        execute("modifyvm", @uuid, "--macaddress1", mac)
      end

      def set_name(name)
        execute("modifyvm", @uuid, "--name", name, :retryable => true)
      end

      def share_folders(folders)
        folders.each do |folder|
          args = ["--name",
                  folder[:name],
                  "--hostpath",
                  folder[:hostpath]]
          args << "--transient" if folder.has_key?(:transient) && folder[:transient]
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

      def start(mode)
        command = ["startvm", @uuid, "--type", mode.to_s]
        r = raw(*command)

        if r.exit_code == 0 || r.stdout =~ /VM ".+?" has been successfully started/
          # Some systems return an exit code 1 for some reason. For that
          # we depend on the output.
          return true
        end

        # If we reached this point then it didn't work out.
        raise Errors::VBoxManageError, :command => command.inspect
      end

      def suspend
        execute("controlvm", @uuid, "savestate")
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

      protected

      # JANK MODE METHODS:
      #
      # All the methods below are created to work around a horrendous
      # bug in VirtualBox 4.2.0 on Windows where "showvminfo --machinereadable"
      # doesn't output enough data. So, instead, on Windows we use the plain
      # "showvminfo" and parse the human readable output.

      def jank_clear_shared_folders
        info = execute("showvminfo", @uuid, :retryable => true)

        # Get the shared folders part
        info = info.split("\n")
        info = info.drop_while { |line| line !~ /^Shared folders:/i }
        info = info.take_while { |line| line != "" && line !~ /^Name:/i }

        # Find all the shared folders and delete them all
        info.each do |line|
          if line =~ /^Name: '(.+?)'/
            execute("sharedfolder", "remove", @uuid, "--name", $1.to_s)
          end
        end
      end

      def jank_read_forwarded_ports(uuid, active_only)
        results = []

        info = execute("showvminfo", uuid, :retryable => true)
        info.split("\n").each do |line|
          # If we care about active VMs only, then we check the state
          # to verify the VM is running.
          if active_only && line =~ /^State:\s+(.+?) \(.+?\)$/ && $1.to_s != "running"
            return []
          end

          # Parse out the forwarded port information
          if line =~ /^NIC (\d) Rule\(\d\):\s+name = (.+?), protocol = .+?, host ip = .*?, host port = (.+?), guest ip = .*?, guest port = (.+?)$/
            result = [$1.to_i, $2.to_s, $3.to_i, $4.to_i]
            @logger.debug("  - #{result.inspect}")
            results << result
          end
        end

        results
      end

      def jank_read_hostonly_adapters(uuid)
        adapters = []

        nics = jank_read_network_interfaces(uuid)
        nics.each do |adapter, data|
          if data[:type] == :hostonly
            adapters << data[:hostonly]
          end
        end

        adapters
      end

      def jank_read_mac_address
        info = execute("showvminfo", @uuid, :retryable => true)
        info.split("\n").each do |line|
          return $1.to_s if line =~ /^NIC 1:\s+MAC: (.+?),/
        end

        nil
      end

      def jank_read_network_interfaces(uuid=nil)
        uuid ||= @uuid
        nics = {}
        info = execute("showvminfo", uuid, :retryable => true)
        info.split("\n").each do |line|
          if line =~ /^NIC (\d):\s+MAC: .+?, Attachment: (.+?), Cable/
            adapter = $1.to_i
            long_type = $2.to_s

            type = nil
            data = nil
            if long_type == "NAT"
              type = :nat
            elsif long_type =~ /^Host-only Interface '(.+?)'$/i
              type = :hostonly
              data = $1.to_s
            elsif long_type =~ /^Bridged Interface '(.+?)'$/i
              type = :bridge
              data = $1.to_s
            end

            nics[adapter] ||= {}
            nics[adapter][:type] = type
            nics[adapter][:hostonly] = data if type == :hostonly
            nics[adapter][:bridge] = data if type == :bridge
          end
        end

        nics
      end

      def jank_read_state
        output = execute("showvminfo", @uuid, :retryable => true)
        if output =~ /^Name:\s+<inaccessible>$/
          return :inaccessible
        elsif output =~ /^State:\s+(.+?) \(.+?\)$/
          # Silly edge cases for a jank mode. This probably doesn't
          # cover every case, but if we can get Vagrant MOSTLY working
          # with this buggy version of VirtualBox on Windows, I'll be
          # quite happy.
          state = $1.to_s.downcase.gsub(" ", "")
          state = "poweroff" if state == "poweredoff"
          return state.to_sym
        end

        nil
      end
    end
  end
end
