require "json"

require "vagrant/util/powershell"

require_relative "plugin"

module VagrantPlugins
  module HyperV
    class Driver
      ERROR_REGEXP  = /===Begin-Error===(.+?)===End-Error===/m
      OUTPUT_REGEXP = /===Begin-Output===(.+?)===End-Output===/m

      attr_reader :vm_id

      def initialize(id)
        @vm_id = id
      end

      def execute(path, options)
        r = execute_powershell(path, options)
        if r.exit_code != 0
          raise Errors::PowerShellError,
            script: path,
            stderr: r.stderr
        end

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

        # Nothing
        return nil if !output_match
        return JSON.parse(output_match[1])
      end

      def get_current_state
        execute('get_vm_status.ps1', { VmId: vm_id })
      end

       def delete_vm
         execute('delete_vm.ps1', { VmId: vm_id })
       end

      def export(path)
        execute('export_vm.ps1', {VmId: vm_id, Path: path})
      end

       def read_guest_ip
         execute('get_network_config.ps1', { VmId: vm_id })
       end

      def read_mac_address
        execute('get_network_mac.ps1', { VmId: vm_id })
      end

       def resume
         execute('resume_vm.ps1', { VmId: vm_id })
       end

       def start
         execute('start_vm.ps1', { VmId: vm_id })
       end

       def stop
         execute('stop_vm.ps1', { VmId: vm_id })
       end

       def suspend
         execute("suspend_vm.ps1", { VmId: vm_id })
       end

       def import(options)
         config_type = options.delete(:vm_config_type)
         if config_type === "vmcx"
           execute('import_vm_vmcx.ps1', options)
         else
           options.delete(:data_path)
           options.delete(:source_path)
           options.delete(:differencing_disk)
           execute('import_vm_xml.ps1', options)
         end
       end

       def net_set_vlan(vlan_id)
          execute("set_network_vlan.ps1", { VmId: vm_id, VlanId: vlan_id })
       end

       def net_set_mac(mac_addr)
          execute("set_network_mac.ps1", { VmId: vm_id, Mac: mac_addr })
       end

       def create_snapshot(snapshot_name)
          execute("create_snapshot.ps1", { VmId: vm_id, SnapName: (snapshot_name) } )
       end

       def restore_snapshot(snapshot_name)
          execute("restore_snapshot.ps1", { VmId: vm_id,  SnapName: (snapshot_name) } )
       end

       def list_snapshots()
          snaps = execute("list_snapshots.ps1", { VmID: vm_id } )
          snaps.map { |s| s['Name'] }
       end

       def delete_snapshot(snapshot_name)
          execute("delete_snapshot.ps1", {VmID: vm_id, SnapName: snapshot_name})
       end

      def set_vm_integration_services(config)
        execute("set_vm_integration_services.ps1", config)
      end

      protected

      def execute_powershell(path, options, &block)
        lib_path = Pathname.new(File.expand_path("../scripts", __FILE__))
        path = lib_path.join(path).to_s.gsub("/", "\\")
        options = options || {}
        ps_options = []
        options.each do |key, value|
          ps_options << "-#{key}"
          ps_options << "'#{value}'"
        end

        # Always have a stop error action for failures
        ps_options << "-ErrorAction" << "Stop"

        opts = { notify: [:stdout, :stderr, :stdin] }
        Vagrant::Util::PowerShell.execute(path, *ps_options, **opts, &block)
      end
    end
  end
end
