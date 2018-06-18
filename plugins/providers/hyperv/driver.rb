require "json"

require "vagrant/util/powershell"

require_relative "plugin"

module VagrantPlugins
  module HyperV
    class Driver
      ERROR_REGEXP  = /===Begin-Error===(.+?)===End-Error===/m
      OUTPUT_REGEXP = /===Begin-Output===(.+?)===End-Output===/m

      # Name mapping for integration services for nicer keys
      INTEGRATION_SERVICES_MAP = {
        guest_service_interface: "Guest Service Interface",
        heartbeat: "Heartbeat",
        key_value_pair_exchange: "Key-Value Pair Exchange",
        shutdown: "Shutdown",
        time_synchronization: "Time Synchronization",
        vss: "VSS",
      }

      # @return [String] VM ID
      attr_reader :vm_id

      def initialize(id)
        @vm_id = id
      end

      # @return [Boolean] Supports VMCX
      def has_vmcx_support?
        !!execute(:has_vmcx_support)["result"]
      end

      # Execute a PowerShell command and process the results
      #
      # @param [String] path Path to PowerShell script
      # @param [Hash] options Options to pass to command
      #
      # @return [Object, nil] If the command returned JSON content
      #                       it will be parsed and returned, otherwise
      #                       nil will be returned
      def execute(path, options={})
        if path.is_a?(Symbol)
          path = "#{path}.ps1"
        end
        r = execute_powershell(path, options)

        # We only want unix-style line endings within Vagrant
        r.stdout.gsub!("\r\n", "\n")
        r.stderr.gsub!("\r\n", "\n")

        error_match  = ERROR_REGEXP.match(r.stdout)
        output_match = OUTPUT_REGEXP.match(r.stdout)

        if error_match
          data = JSON.parse(error_match[1])

          # We have some error data.
          raise Errors::PowerShellError,
            script: path,
            stderr: data["error"]
        end

        if r.exit_code != 0
          raise Errors::PowerShellError,
            script: path,
            stderr: r.stderr
        end

        # Nothing
        return nil if !output_match
        return JSON.parse(output_match[1])
      end

      # Fetch current state of the VM
      #
      # @return [Hash<state, status>]
      def get_current_state
        execute(:get_vm_status, VmId: vm_id)
      end

      # Delete the VM
      #
      # @return [nil]
      def delete_vm
        execute(:delete_vm, VmId: vm_id)
      end

      # Export the VM to the given path
      #
      # @param [String] path Path for export
      # @return [nil]
      def export(path)
        execute(:export_vm, VmId: vm_id, Path: path)
      end

      # Get the IP address of the VM
      #
      # @return [Hash<ip>]
      def read_guest_ip
        execute(:get_network_config, VmId: vm_id)
      end

      # Get the MAC address of the VM
      #
      # @return [Hash<mac>]
      def read_mac_address
        execute(:get_network_mac, VmId: vm_id)
      end

      # Resume the VM from suspension
      #
      # @return [nil]
      def resume
        execute(:resume_vm, VmId: vm_id)
      end

      # Start the VM
      #
      # @return [nil]
      def start
        execute(:start_vm, VmId: vm_id )
      end

      # Stop the VM
      #
      # @return [nil]
      def stop
        execute(:stop_vm, VmId: vm_id)
      end

      # Suspend the VM
      #
      # @return [nil]
      def suspend
        execute(:suspend_vm, VmId: vm_id)
      end

      # Import a new VM
      #
      # @param [Hash] options Configuration options
      # @return [Hash<id>] New VM ID
      def import(options)
        execute(:import_vm, options)
      end

      # Set the VLAN ID
      #
      # @param [String] vlan_id VLAN ID
      # @return [nil]
      def net_set_vlan(vlan_id)
        execute(:set_network_vlan, VmId: vm_id, VlanId: vlan_id)
      end

      # Set the VM adapter MAC address
      #
      # @param [String] mac_addr MAC address
      # @return [nil]
      def net_set_mac(mac_addr)
        execute(:set_network_mac, VmId: vm_id, Mac: mac_addr)
      end

      # Create a new snapshot with the given name
      #
      # @param [String] snapshot_name Name of the new snapshot
      # @return [nil]
      def create_snapshot(snapshot_name)
        execute(:create_snapshot, VmId: vm_id, SnapName: snapshot_name)
      end

      # Restore the given snapshot
      #
      # @param [String] snapshot_name Name of snapshot to restore
      # @return [nil]
      def restore_snapshot(snapshot_name)
        execute(:restore_snapshot, VmId: vm_id,  SnapName: snapshot_name)
      end

      # Get list of current snapshots
      #
      # @return [Array<String>] snapshot names
      def list_snapshots
        snaps = execute(:list_snapshots, VmID: vm_id)
        snaps.map { |s| s['Name'] }
      end

      # Delete snapshot with the given name
      #
      # @param [String] snapshot_name Name of snapshot to delete
      # @return [nil]
      def delete_snapshot(snapshot_name)
        execute(:delete_snapshot, VmID: vm_id, SnapName: snapshot_name)
      end

      # Enable or disable VM integration services
      #
      # @param [Hash] config Integration services to enable or disable
      # @return [nil]
      # @note Keys in the config hash will be remapped if found in the
      #       INTEGRATION_SERVICES_MAP. If they are not, the name will
      #       be passed directly. This allows new integration services
      #       to configurable even if Vagrant is not aware of them.
      def set_vm_integration_services(config)
        config.each_pair do |srv_name, srv_enable|
          args = {VMID: vm_id, Name: INTEGRATION_SERVICES_MAP.fetch(srv_name.to_sym, srv_name).to_s}
          args[:Enable] = true if srv_enable
          execute(:set_vm_integration_services, args)
        end
      end

      # Set the name of the VM
      #
      # @param [String] vmname Name of the VM
      # @return [nil]
      def set_name(vmname)
        execute(:set_name, VMID: vm_id, VMName: vmname)
      end

      protected

      def execute_powershell(path, options, &block)
        lib_path = Pathname.new(File.expand_path("../scripts", __FILE__))
        mod_path = Vagrant::Util::Platform.wsl_to_windows_path(lib_path.join("utils")).to_s.gsub("/", "\\")
        path = Vagrant::Util::Platform.wsl_to_windows_path(lib_path.join(path)).to_s.gsub("/", "\\")
        options = options || {}
        ps_options = []
        options.each do |key, value|
          next if value == false
          ps_options << "-#{key}"
          # If the value is a TrueClass assume switch
          next if value == true
          ps_options << "'#{value}'"
        end

        # Always have a stop error action for failures
        ps_options << "-ErrorAction" << "Stop"

        # Include our module path so we can nicely load helper modules
        opts = {
          notify: [:stdout, :stderr, :stdin],
          module_path: mod_path
        }

        Vagrant::Util::PowerShell.execute(path, *ps_options, **opts, &block)
      end
    end
  end
end
