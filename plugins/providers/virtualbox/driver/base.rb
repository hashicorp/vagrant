require 'log4r'

require 'vagrant/util/busy'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require 'vagrant/util/subprocess'

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      # Base class for all VirtualBox drivers.
      #
      # This class provides useful tools for things such as executing
      # VBoxManage and handling SIGINTs and so on.
      class Base
        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable

        def initialize
          @logger = Log4r::Logger.new("vagrant::provider::virtualbox::base")

          # This flag is used to keep track of interrupted state (SIGINT)
          @interrupted = false

          # Set the path to VBoxManage
          @vboxmanage_path = "VBoxManage"

          if Vagrant::Util::Platform.windows? || Vagrant::Util::Platform.cygwin?
            @logger.debug("Windows. Trying VBOX_INSTALL_PATH for VBoxManage")

            # On Windows, we use the VBOX_INSTALL_PATH environmental
            # variable to find VBoxManage.
            if ENV.has_key?("VBOX_INSTALL_PATH")
              # Get the path.
              path = ENV["VBOX_INSTALL_PATH"]
              @logger.debug("VBOX_INSTALL_PATH value: #{path}")

              # There can actually be multiple paths in here, so we need to
              # split by the separator ";" and see which is a good one.
              path.split(";").each do |single|
                # Make sure it ends with a \
                single += "\\" if !single.end_with?("\\")

                # If the executable exists, then set it as the main path
                # and break out
                vboxmanage = "#{path}VBoxManage.exe"
                if File.file?(vboxmanage)
                  @vboxmanage_path = Vagrant::Util::Platform.cygwin_windows_path(vboxmanage)
                  break
                end
              end
            end
          end

          @logger.info("VBoxManage path: #{@vboxmanage_path}")
        end

        # Clears the forwarded ports that have been set on the virtual machine.
        def clear_forwarded_ports
        end

        # Clears the shared folders that have been set on the virtual machine.
        def clear_shared_folders
        end

        # Creates a DHCP server for a host only network.
        #
        # @param [String] network Name of the host-only network.
        # @param [Hash] options Options for the DHCP server.
        def create_dhcp_server(network, options)
        end

        # Creates a host only network with the given options.
        #
        # @param [Hash] options Options to create the host only network.
        # @return [Hash] The details of the host only network, including
        #   keys `:name`, `:ip`, and `:netmask`
        def create_host_only_network(options)
        end

        # Deletes the virtual machine references by this driver.
        def delete
        end

        # Deletes any host only networks that aren't being used for anything.
        def delete_unused_host_only_networks
        end

        # Discards any saved state associated with this VM.
        def discard_saved_state
        end

        # Enables network adapters on the VM.
        #
        # The format of each adapter specification should be like so:
        #
        # {
        #   :type     => :hostonly,
        #   :hostonly => "vboxnet0",
        #   :mac_address => "tubes"
        # }
        #
        # This must support setting up both host only and bridged networks.
        #
        # @param [Array<Hash>] adapters Array of adapters to enable.
        def enable_adapters(adapters)
        end

        # Execute a raw command straight through to VBoxManage.
        #
        # @param [Array] command Command to execute.
        def execute_command(command)
        end

        # Exports the virtual machine to the given path.
        #
        # @param [String] path Path to the OVF file.
        # @yield [progress] Yields the block with the progress of the export.
        def export(path)
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
        end

        # Halts the virtual machine (pulls the plug).
        def halt
        end

        # Imports the VM from an OVF file.
        #
        # @param [String] ovf Path to the OVF file.
        # @return [String] UUID of the imported VM.
        def import(ovf)
        end

        # Returns the maximum number of network adapters.
        def max_network_adapters
          8
        end

        # Returns a list of forwarded ports for a VM.
        #
        # @param [String] uuid UUID of the VM to read from, or `nil` if this
        #   VM.
        # @param [Boolean] active_only If true, only VMs that are running will
        #   be checked.
        # @return [Array<Array>]
        def read_forwarded_ports(uuid=nil, active_only=false)
        end

        # Returns a list of bridged interfaces.
        #
        # @return [Hash]
        def read_bridged_interfaces
        end

        # Returns the guest additions version that is installed on this VM.
        #
        # @return [String]
        def read_guest_additions_version
        end

        # Returns a list of available host only interfaces.
        #
        # @return [Hash]
        def read_host_only_interfaces
        end

        # Returns the MAC address of the first network interface.
        #
        # @return [String]
        def read_mac_address
        end

        # Returns the folder where VirtualBox places it's VMs.
        #
        # @return [String]
        def read_machine_folder
        end

        # Returns a list of network interfaces of the VM.
        #
        # @return [Hash]
        def read_network_interfaces
        end

        # Returns the current state of this VM.
        #
        # @return [Symbol]
        def read_state
        end

        # Returns a list of all forwarded ports in use by active
        # virtual machines.
        #
        # @return [Array]
        def read_used_ports
        end

        # Returns a list of all UUIDs of virtual machines currently
        # known by VirtualBox.
        #
        # @return [Array<String>]
        def read_vms
        end

        # Sets the MAC address of the first network adapter.
        #
        # @param [String] mac MAC address without any spaces/hyphens.
        def set_mac_address(mac)
        end

        # Share a set of folders on this VM.
        #
        # @param [Array<Hash>] folders
        def share_folders(folders)
        end

        # Reads the SSH port of this VM.
        #
        # @param [Integer] expected Expected guest port of SSH.
        def ssh_port(expected)
        end

        # Starts the virtual machine.
        #
        # @param [String] mode Mode to boot the VM. Either "headless"
        #   or "gui"
        def start(mode)
        end

        # Suspend the virtual machine.
        def suspend
        end

        # Verifies that the driver is ready to accept work.
        #
        # This should raise a VagrantError if things are not ready.
        def verify!
        end

        # Verifies that an image can be imported properly.
        #
        # @param [String] path Path to an OVF file.
        # @return [Boolean]
        def verify_image(path)
        end

        # Checks if a VM with the given UUID exists.
        #
        # @return [Boolean]
        def vm_exists?(uuid)
        end

        # Execute the given subcommand for VBoxManage and return the output.
        def execute(*command, &block)
          # Get the options hash if it exists
          opts = {}
          opts = command.pop if command.last.is_a?(Hash)

          tries = 0
          tries = 3 if opts[:retryable]

          # Variable to store our execution result
          r = nil

          # If there is an error with VBoxManage, this gets set to true
          errored = false

          retryable(:on => Vagrant::Errors::VBoxManageError, :tries => tries, :sleep => 1) do
            # Execute the command
            r = raw(*command, &block)

            # If the command was a failure, then raise an exception that is
            # nicely handled by Vagrant.
            if r.exit_code != 0
              if @interrupted
                @logger.info("Exit code != 0, but interrupted. Ignoring.")
              elsif r.exit_code == 126
                # This exit code happens if VBoxManage is on the PATH,
                # but another executable it tries to execute is missing.
                # This is usually indicative of a corrupted VirtualBox install.
                raise Vagrant::Errors::VBoxManageNotFoundError
              else
                errored = true
              end
            else
              # Sometimes, VBoxManage fails but doesn't actual return a non-zero
              # exit code. For this we inspect the output and determine if an error
              # occurred.

              if r.stderr =~ /failed to open \/dev\/vboxnetctl/i
                # This catches an error message that only shows when kernel
                # drivers aren't properly installed.
                @logger.error("Error message about unable to open vboxnetctl")
                raise Vagrant::Errors::VirtualBoxKernelModuleNotLoaded
              end

              if r.stderr =~ /VBoxManage([.a-z]+?): error:/
                # This catches the generic VBoxManage error case.
                @logger.info("VBoxManage error text found, assuming error.")
                errored = true
              end
            end
          end

          # If there was an error running VBoxManage, show the error and the
          # output.
          if errored
            raise Vagrant::Errors::VBoxManageError,
              :command => command.inspect,
              :stderr  => r.stderr
          end

          # Return the output, making sure to replace any Windows-style
          # newlines with Unix-style.
          r.stdout.gsub("\r\n", "\n")
        end

        # Executes a command and returns the raw result object.
        def raw(*command, &block)
          int_callback = lambda do
            @interrupted = true
            @logger.info("Interrupted.")
          end

          # Append in the options for subprocess
          command << { :notify => [:stdout, :stderr] }

          Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(@vboxmanage_path, *command, &block)
          end
        end
      end
    end
  end
end
