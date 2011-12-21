require 'log4r'
require 'vagrant/util/subprocess'

module Vagrant
  module Driver
    # This class contains the logic to drive VirtualBox.
    class VirtualBox
      # Include this so we can use `Subprocess` more easily.
      include Vagrant::Util

      # The version of virtualbox that is running.
      attr_reader :version

      def initialize(uuid)
        @logger = Log4r::Logger.new("vagrant::driver::virtualbox")
        @uuid = uuid

        # Read and assign the version of VirtualBox we know which
        # specific driver to instantiate.
        begin
          @version = read_version
        rescue Subprocess::ProcessFailedToStart
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
          if line =~ /^".+?"\s+{(.+?)}$/
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
        execute("import", ovf, "--vsys", "0", "--vmname", name)
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

      # This reads the guest additions version for a VM.
      def read_guest_additions_version
        output = execute("guestproperty", "get", @uuid, "/VirtualBox/GuestAdd/Version")
        return $1.to_s if output =~ /^Value: (.+?)$/
        return nil
      end

      # This reads the folder where VirtualBox places it's VMs.
      def read_machine_folder
        execute("list", "systemproperties").split("\n").each do |line|
          if line =~ /^Default machine folder:\s+(.+?)$/
            return $1.to_s
          end
        end

        nil
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
            read_forwarded_ports($1.to_s, true).each do |_, _, hostport, _|
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

      protected

      # This returns the version of VirtualBox that is running.
      #
      # @return [String]
      def read_version
        execute("--version").split("r")[0]
      end

      # Execute the given subcommand for VBoxManage and return the output.
      def execute(*command)
        # TODO: Detect failures and handle them
        r = Subprocess.execute("VBoxManage", *command)
        if r.exit_code != 0
          raise Exception, "FAILURE: #{r.stderr}"
        end
        r.stdout
      end
    end
  end
end
