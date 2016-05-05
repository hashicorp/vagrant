require "digest/md5"
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
        @creds  = {}
      end

      def usable?(machine, raise_error=false)
        if !machine.env.host.capability?(:smb_installed)
          raise Errors::HostCapabilityRequired if raise_error
          return false
        else 
          return true
        end
      end

      def prepare(machine, folders, opts)
        machine.ui.output(I18n.t("vagrant_sf_smb.preparing"))

        # If we need auth information, then ask the user.
        have_auth = false
        folders.each do |id, data|
          @creds[:username] ||= data[:smb_username]
          @creds[:password] ||= data[:smb_password]
          if data[:smb_username] && data[:smb_password]
            have_auth = true
            break
          end
        end

        if !have_auth
          machine.ui.detail(I18n.t("vagrant_sf_smb.warning_password") + "\n ")
          @creds[:username] ||= machine.ui.ask("Username: ")
          @creds[:password] ||= machine.ui.ask("Password (will be hidden): ", echo: false)
        end

        machine.env.host.capability(:smb_share, folders, machine.id)
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
          if nfsopts[:smb_host_ip]
            host_ip = nfsopts[:smb_host_ip]
          else
            candidate_ips = load_host_ips
            @logger.debug("Potential host IPs: #{candidate_ips.inspect}")
            host_ip = machine.guest.capability(
              :choose_addressable_ip_addr, candidate_ips)
            if !host_ip
              raise Errors::NoHostIPAddr
            end
          end
        end

        # This is used for defaulting the owner/group
        ssh_info = machine.ssh_info

        folders.each do |id, data|
          data = data.dup
          data[:smb_host] ||= host_ip
          data[:smb_username] ||= @creds[:username]
          data[:smb_password] ||= @creds[:password]

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
        ids = opts[:smb_valid_ids]
        @logger.info("SMB cleanup. Removing dead shares. Valid IDs: #{ids.inspect}")
        ids.collect!{|id| Digest::MD5.hexdigest(id)}
        @logger.debug("Hashed IDs: #{ids.inspect}")
        script_list_path =  "/usr/bin/net usershare list"
        script_delete_path =  "/usr/bin/net usershare delete"
        IO.popen("#{script_list_path}") {|out|
          share_list = out.read
          @logger.debug("Shares found: #{share_list}")
          share_list.each_line{|s|
            @logger.debug("Looking for matches for #{s}")
            id_to_check = s[/.*-/]
            id_to_check = id_to_check.chomp("-") if id_to_check
            @logger.debug("Checking for hashed machine id: #{id_to_check}")
            if id_to_check && !ids.include?(id_to_check)
              @logger.info("Deleting share: #{s}")
              IO.popen("#{script_delete_path} #{s}") {|out| @logger.debug(out.read)}
            end
          }
        }
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
