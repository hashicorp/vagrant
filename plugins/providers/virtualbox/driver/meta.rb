require "forwardable"
require "thread"

require "log4r"

require "vagrant/util/retryable"

require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module ProviderVirtualBox
    module Driver
      class Meta < Base
        # This is raised if the VM is not found when initializing a driver
        # with a UUID.
        class VMNotFound < StandardError; end

        # We use forwardable to do all our driver forwarding
        extend Forwardable

        # We cache the read VirtualBox version here once we have one,
        # since during the execution of Vagrant, it likely doesn't change.
        @@version = nil
        @@version_lock = Mutex.new

        # The UUID of the virtual machine we represent
        attr_reader :uuid

        # The version of virtualbox that is running.
        attr_reader :version

        include Vagrant::Util::Retryable

        def initialize(uuid=nil)
          # Setup the base
          super()

          @logger = Log4r::Logger.new("vagrant::provider::virtualbox::meta")
          @uuid = uuid

          @@version_lock.synchronize do
            if !@@version
              # Read and assign the version of VirtualBox we know which
              # specific driver to instantiate.
              begin
                @@version = read_version
              rescue Vagrant::Errors::CommandUnavailable,
                Vagrant::Errors::CommandUnavailableWindows
                # This means that VirtualBox was not found, so we raise this
                # error here.
                raise Vagrant::Errors::VirtualBoxNotDetected
              end
            end
          end

          # Instantiate the proper version driver for VirtualBox
          @logger.debug("Finding driver for VirtualBox version: #{@@version}")
          driver_map   = {
            "4.0" => Version_4_0,
            "4.1" => Version_4_1,
            "4.2" => Version_4_2,
            "4.3" => Version_4_3,
            "5.0" => Version_5_0,
            "5.1" => Version_5_1,
            "5.2" => Version_5_2,
          }

          if @@version.start_with?("4.2.14")
            # VirtualBox 4.2.14 just doesn't work with Vagrant, so show error
            raise Vagrant::Errors::VirtualBoxBrokenVersion040214
          end

          driver_klass = nil
          driver_map.each do |key, klass|
            if @@version.start_with?(key)
              driver_klass = klass
              break
            end
          end

          if !driver_klass
            supported_versions = driver_map.keys.sort.join(", ")
            raise Vagrant::Errors::VirtualBoxInvalidVersion,
              supported_versions: supported_versions
          end

          @logger.info("Using VirtualBox driver: #{driver_klass}")
          @driver = driver_klass.new(@uuid)
          @version = @@version

          if @uuid
            # Verify the VM exists, and if it doesn't, then don't worry
            # about it (mark the UUID as nil)
            raise VMNotFound if !@driver.vm_exists?(@uuid)
          end
        end

        def_delegators :@driver, :clear_forwarded_ports,
          :clear_shared_folders,
          :clonevm,
          :create_dhcp_server,
          :create_host_only_network,
          :create_snapshot,
          :delete,
          :delete_snapshot,
          :delete_unused_host_only_networks,
          :discard_saved_state,
          :enable_adapters,
          :execute_command,
          :export,
          :forward_ports,
          :halt,
          :import,
          :list_snapshots,
          :read_forwarded_ports,
          :read_bridged_interfaces,
          :read_dhcp_servers,
          :read_guest_additions_version,
          :read_guest_ip,
          :read_guest_property,
          :read_host_only_interfaces,
          :read_mac_address,
          :read_mac_addresses,
          :read_machine_folder,
          :read_network_interfaces,
          :read_state,
          :read_used_ports,
          :read_vms,
          :reconfig_host_only,
          :remove_dhcp_server,
          :restore_snapshot,
          :resume,
          :set_mac_address,
          :set_name,
          :share_folders,
          :ssh_port,
          :start,
          :suspend,
          :verify!,
          :verify_image,
          :vm_exists?

        protected

        # This returns the version of VirtualBox that is running.
        #
        # @return [String]
        def read_version
          # The version string is usually in one of the following formats:
          #
          # * 4.1.8r1234
          # * 4.1.8r1234_OSE
          # * 4.1.8_MacPortsr1234
          #
          # Below accounts for all of these.

          # Note: We split this into multiple lines because apparently "".split("_")
          # is [], so we have to check for an empty array in between.
          output = ""
          retryable(on: Vagrant::Errors::VirtualBoxVersionEmpty, tries: 3, sleep: 1) do
            output = execute("--version")
            if output =~ /vboxdrv kernel module is not loaded/ ||
              output =~ /VirtualBox kernel modules are not loaded/i
              raise Vagrant::Errors::VirtualBoxKernelModuleNotLoaded
            elsif output =~ /Please install/
              # Check for installation incomplete warnings, for example:
              # "WARNING: The character device /dev/vboxdrv does not
              # exist. Please install the virtualbox-ose-dkms package and
              # the appropriate headers, most likely linux-headers-generic."
              raise Vagrant::Errors::VirtualBoxInstallIncomplete
            elsif output.chomp == ""
              # This seems to happen on Windows for uncertain reasons.
              # Raise an error otherwise the error is that they have an
              # incompatible version of VirtualBox which isn't true.
              raise Vagrant::Errors::VirtualBoxVersionEmpty,
                vboxmanage: @vboxmanage_path.to_s
            end
          end

          parts = output.split("_")
          return nil if parts.empty?
          parts[0].split("r")[0]
        end
      end
    end
  end
end
