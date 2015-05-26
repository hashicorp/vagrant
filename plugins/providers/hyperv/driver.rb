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

      def read_guest_ip
        execute('get_network_config.ps1', { VmId: vm_id })
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
        execute('import_vm.ps1', options)
      end

      def enable_adapters(adapters)
        nics = {}
        nics[:VmId] = vm_id
        nics[:Adapters] = adapters.to_json.gsub('"', '\"')

        execute("enable_adapters.ps1", nics)
      end

      def read_network_interfaces
        nics = {}
        info = execute('get_network_interfaces.ps1', { VmId: vm_id })
        info.each_with_index do |nic, index|
            adapter = index + 1

            nics[adapter] ||= {}
            nics[adapter][:network_name] = nic["SwitchName"]
            nics[adapter][:mac_address] = nic["MacAddress"]
            nics[adapter][:id] = nic["Id"]
        end

        nics
      end

      # Share a set of folders on this VM.
      #
      # @param [Array<Hash>] folders
      def share_folders(folders)
      end

      def read_mac_addresses
        nics = {}
        info = execute('get_network_interfaces.ps1', { VmId: vm_id })
        info.each_with_index do |nic, index|
            adapter = index + 1

            nics[adapter] = nic["MacAddress"].gsub(":", "")
        end
        nics
      end

      protected

      def execute_powershell(path, options, &block)
        lib_path = Pathname.new(File.expand_path("../scripts", __FILE__))
        path = lib_path.join(path).to_s.gsub("/", "\\")
        options = options || {}
        ps_options = []
        options.each do |key, value|
          ps_options << "-#{key}"
          ps_options << "#{value}"
        end

        # Always have a stop error action for failures
        ps_options << "-ErrorAction" << "Stop"

        opts = { notify: [:stdout, :stderr, :stdin] }
        Vagrant::Util::PowerShell.execute(path, *ps_options, **opts, &block)
      end
    end
  end
end
