require 'log4r'
require 'vagrant/util/busy'
require 'vagrant/util/subprocess'

module Vagrant
  module Driver
    # This class contains the logic to drive VirtualBox.
    class VirtualBox
      # This is raised if the VM is not found when initializing a driver
      # with a UUID.
      class VMNotFound < StandardError; end

      # Include this so we can use `Subprocess` more easily.
      include Vagrant::Util

      # The UUID of the virtual machine we represent
      attr_reader :uuid

      # The version of virtualbox that is running.
      attr_reader :version

      def initialize(uuid)
        @logger = Log4r::Logger.new("vagrant::driver::virtualbox")
        @uuid = uuid

        # This flag is used to keep track of interrupted state (SIGINT)
        @interrupted = false

        if @uuid
          # Verify the VM exists, and if it doesn't, then don't worry
          # about it (mark the UUID as nil)
          r = raw("showvminfo", @uuid)
          raise VMNotFound if r.exit_code != 0
        end

        # Read and assign the version of VirtualBox we know which
        # specific driver to instantiate.
        begin
          @version = read_version
        rescue Subprocess::LaunchError
          # This means that VirtualBox was not found, so we raise this
          # error here.
          raise Errors::VirtualBoxNotDetected
        end
      end

      # This clears the forwarded ports that have been set on the
      # virtual machine.
      def clear_forwarded_ports
        args = []
        read_forwarded_ports(@uuid).each do |nic, name, _, _|
          args.concat(["--natpf#{nic}", "delete", name])
        end

        execute("modifyvm", @uuid, *args) if !args.empty?
      end

      # This clears all the shared folders that have been set
      # on the virtual machine.
      def clear_shared_folders
        execute("showvminfo", @uuid, "--machinereadable").split("\n").each do |line|
          if line =~ /^SharedFolderNameMachineMapping\d+="(.+?)"$/
            execute("sharedfolder", "remove", @uuid, "--name", $1.to_s)
          end
        end
      end

      # Creates a host only network with the given options.
      def create_host_only_network(options)
        # Create the interface
        execute("hostonlyif", "create") =~ /^Interface '(.+?)' was successfully created$/
        name = $1.to_s

        # Configure it
        execute("hostonlyif", "ipconfig", name,
                "--ip", options[:ip],
                "--netmask", options[:netmask])

        # Return the details
        return {
          :name => name,
          :ip   => options[:ip],
          :netmask => options[:netmask]
        }
      end

      # This deletes the VM with the given name.
      def delete
        execute("unregistervm", @uuid, "--delete")
      end

      # Deletes any host only networks that aren't being used for anything.
      def delete_unused_host_only_networks
        networks = []
        execute("list", "hostonlyifs").split("\n").each do |line|
          networks << $1.to_s if line =~ /^Name:\s+(.+?)$/
        end

        execute("list", "vms").split("\n").each do |line|
          if line =~ /^".+?"\s+\{(.+?)\}$/
            execute("showvminfo", $1.to_s, "--machinereadable").split("\n").each do |info|
              if info =~ /^hostonlyadapter\d+="(.+?)"$/
                networks.delete($1.to_s)
              end
            end
          end
        end

        networks.each do |name|
          execute("hostonlyif", "remove", name)
        end
      end

      # Discards any saved state associated with this VM.
      def discard_saved_state
        execute("discardstate", @uuid)
      end

      # Enables network adapters on this virtual machine.
      def enable_adapters(adapters)
        args = []
        adapters.each do |adapter|
          args.concat(["--nic#{adapter[:adapter]}", adapter[:type].to_s])

          if adapter[:hostonly]
            args.concat(["--hostonlyadapter#{adapter[:adapter]}",
                         adapter[:hostonly]])
          end

          if adapter[:mac_address]
            args.concat(["--macaddress#{adapter[:adapter]}",
                         adapter[:mac_address]])
          end
        end

        execute("modifyvm", @uuid, *args)
      end

      # Executes a raw command.
      def execute_command(command)
        raw(*command)
      end

      # Exports the virtual machine to the given path.
      #
      # @param [String] path Path to the OVF file.
      def export(path)
        # TODO: Progress
        execute("export", @uuid, "--output", path.to_s)
      end

      # Forwards a set of ports for a VM.
      #
      # This will not affect any previously set forwarded ports,
      # so be sure to delete those if you need to.
      #
      # The format of each port hash should be the following:
      #
      #     {
      #       :name => "foo",
      #       :hostport => 8500,
      #       :guestport => 80,
      #       :adapter => 1,
      #       :protocol => "tcp"
      #     }
      #
      # Note that "adapter" and "protocol" are optional and will default
      # to 1 and "tcp" respectively.
      #
      # @param [Array<Hash>] ports An array of ports to set. See documentation
      #   for more information on the format.
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

        execute("modifyvm", @uuid, *args)
      end

      # Halts the virtual machine.
      def halt
        execute("controlvm", @uuid, "poweroff")
      end

      # Imports the VM with the given path to the OVF file. It returns
      # the UUID as a string.
      def import(ovf, name)
        total = ""
        last  = 0
        execute("import", ovf, "--vsys", "0", "--vmname", name) do |type, data|
          if type == :stderr
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

        output = execute("list", "vms")
        if output =~ /^"#{name}" {(.+?)}$/
          return $1.to_s
        end

        nil
      end

      # This returns a list of the forwarded ports in the form
      # of `[nic, name, hostport, guestport]`.
      #
      # @return [Array<Array>]
      def read_forwarded_ports(uuid=nil, active_only=false)
        uuid ||= @uuid

        @logger.debug("read_forward_ports: uuid=#{uuid} active_only=#{active_only}")

        results = []
        current_nic = nil
        execute("showvminfo", uuid, "--machinereadable").split("\n").each do |line|
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

      # This reads the list of host only networks.
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

      # This reads the guest additions version for a VM.
      def read_guest_additions_version
        output = execute("guestproperty", "get", @uuid, "/VirtualBox/GuestAdd/Version")
        return $1.to_s if output =~ /^Value: (.+?)$/
        return nil
      end

      # Reads and returns the available host only interfaces.
      def read_host_only_interfaces
        execute("list", "hostonlyifs").split("\n\n").collect do |block|
          info = {}

          block.split("\n").each do |line|
            if line =~ /^Name:\s+(.+?)$/
              info[:name] = $1.to_s
            elsif line =~ /^IPAddress:\s+(.+?)$/
              info[:ip] = $1.to_s
            elsif line =~ /^NetworkMask:\s+(.+?)$/
              info[:netmask] = $1.to_s
            end
          end

          info
        end
      end

      # Reads the MAC address of the first network interface.
      def read_mac_address
        execute("showvminfo", @uuid, "--machinereadable").split("\n").each do |line|
          return $1.to_s if line =~ /^macaddress1="(.+?)"$/
        end

        nil
      end

      # This reads the folder where VirtualBox places it's VMs.
      def read_machine_folder
        execute("list", "systemproperties").split("\n").each do |line|
          if line =~ /^Default machine folder:\s+(.+?)$/i
            return $1.to_s
          end
        end

        nil
      end

      # This reads the network interfaces and returns various information
      # about them.
      #
      # @return [Hash]
      def read_network_interfaces
        nics = {}
        execute("showvminfo", @uuid, "--machinereadable").split("\n").each do |line|
          if line =~ /^nic(\d+)="(.+?)"$/
            nics[$1.to_i] = {
              :type => $2.to_s
            }
          end
        end

        nics
      end

      # This reads the state for the given UUID. The state of the VM
      # will be returned as a symbol.
      def read_state
        output = execute("showvminfo", @uuid, "--machinereadable")
        if output =~ /^name="<inaccessible>"$/
          return :inaccessible
        elsif output =~ /^VMState="(.+?)"$/
          return $1.to_sym
        end

        nil
      end

      # This will read all the used ports for port forwarding by
      # all virtual machines.
      def read_used_ports
        ports = []
        execute("list", "vms").split("\n").each do |line|
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

      # This sets the MAC address for a network adapter.
      def set_mac_address(mac)
        execute("modifyvm", @uuid, "--macaddress1", mac)
      end

      # Sets up the shared folder metadata for a virtual machine.
      #
      # The structure of a folder definition should be the following:
      #
      #     {
      #       :name => "foo",
      #       :hostpath => "/foo/bar"
      #     }
      #
      # @param [Array<Hash>] folders An array of folder definitions to
      # setup.
      def share_folders(folders)
        folders.each do |folder|
          execute("sharedfolder", "add", @uuid, "--name",
                  folder[:name], "--hostpath", folder[:hostpath])
        end
      end

      # Starts the virtual machine in the given mode.
      #
      # @param [String] mode Mode to boot the VM: either "headless" or "gui"
      def start(mode)
        execute("startvm", @uuid, "--type", mode.to_s)
      end

      # Suspends the virtual machine.
      def suspend
        execute("controlvm", @uuid, "savestate")
      end

      # Verifies that an image can be imported properly.
      #
      # @return [Boolean]
      def verify_image(path)
        r = raw("import", path.to_s, "--dry-run")
        return r.exit_code == 0
      end

      protected

      # This returns the version of VirtualBox that is running.
      #
      # @return [String]
      def read_version
        execute("--version").split("r")[0]
      end

      # Execute the given subcommand for VBoxManage and return the output.
      def execute(*command, &block)
        # Execute the command
        r = raw(*command, &block)

        # If the command was a failure, then raise an exception that is
        # nicely handled by Vagrant.
        if r.exit_code != 0
          if @interrupted
            @logger.info("Exit code != 0, but interrupted. Ignoring.")
          else
            raise Errors::VBoxManageError, :command => command.inspect
          end
        end

        # Return the output
        r.stdout
      end

      # Executes a command and returns the raw result object.
      def raw(*command, &block)
        int_callback = lambda do
          @interrupted = true
          @logger.info("Interrupted.")
        end

        Util::Busy.busy(int_callback) do
          Subprocess.execute("VBoxManage", *command, &block)
        end
      end
    end
  end
end
