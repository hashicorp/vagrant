require "json"

require "log4r"

require "vagrant/util/platform"
require "vagrant/util/powershell"

module VagrantPlugins
  module SyncedFolderSMB
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::synced_folders::smb")
      end

      def usable?(machine, raise_error=false)
        if !Vagrant::Util::Platform.windows?
          # TODO: raise error if specified
          return false
        end

        true
      end

      def prepare(machine, folders, opts)
        script_path = File.expand_path("../scripts/set_share.ps1", __FILE__)

        folders.each do |id, data|
          hostpath = data[:hostpath]

          data[:smb_id] ||= "#{machine.id}-#{id.gsub("/", "-")}"

          args = []
          args << "-path" << hostpath.gsub("/", "\\")
          args << "-share_name" << data[:smb_id]
          #args << "-host_share_username" << "mitchellh"

          r = Vagrant::Util::PowerShell.execute(script_path, *args)
          if r.exit_code != 0
            raise Errors::DefineShareFailed,
              host: hostpath.to_s,
              stderr: r.stderr,
              stdout: r.stdout
          end
        end
      end

      def enable(machine, folders, nfsopts)
        machine.ui.output(I18n.t("vagrant_sf_smb.mounting"))

        # Make sure that this machine knows this dance
        if !machine.guest.capability?(:mount_smb_shared_folder)
          raise Vagrant::Errors::GuestCapabilityNotFound,
            cap: "mount_smb_shared_folder",
            guest: machine.guest.name.to_s
        end

        # Detect the host IP for this guest if one wasn't specified
        # for every folder.
        host_ip = nil
        need_host_ip = false
        folders.each do |id, data|
          if !data[:smb_host]
            need_host_ip = true
            break
          end
        end

        if need_host_ip
          candidate_ips = load_host_ips
          @logger.debug("Potential host IPs: #{candidate_ips.inspect}")
          host_ip = machine.guest.capability(
            :choose_addressable_ip_addr, candidate_ips)
          if !host_ip
            raise Errors::NoHostIPAddr
          end
        end

        # If we need auth information, then ask the user
        username = nil
        password = nil
        need_auth = false
        folders.each do |id, data|
          if !data[:smb_username] || !data[:smb_password]
            need_auth = true
            break
          end
        end

        if need_auth
          machine.ui.detail(I18n.t("vagrant_sf_smb.warning_password") + "\n ")
          username = machine.ui.ask("Username: ")
          password = machine.ui.ask("Password (will be hidden): ", echo: false)
        end

        # This is used for defaulting the owner/group
        ssh_info = machine.ssh_info

        folders.each do |id, data|
          data = data.dup
          data[:smb_host] ||= host_ip
          data[:smb_username] ||= username
          data[:smb_password] ||= password

          # Default the owner/group of the folder to the SSH user
          data[:owner] ||= ssh_info[:username]
          data[:group] ||= ssh_info[:username]

          machine.ui.detail(I18n.t(
            "vagrant_sf_smb.mounting_single",
            host: data[:hostpath].to_s,
            guest: data[:guestpath].to_s))
          machine.guest.capability(
            :mount_smb_shared_folder, data[:smb_id], data[:guestpath], data)
        end
      end

      def cleanup(machine, opts)

      end

      protected

      def load_host_ips
        script_path = File.expand_path("../scripts/host_info.ps1", __FILE__)
        r = Vagrant::Util::PowerShell.execute(script_path)
        if r.exit_code != 0
          raise Errors::PowershellError,
            script: script_path,
            stderr: r.stderr
        end

        JSON.parse(r.stdout)["ip_addresses"]
      end
    end
  end
end
