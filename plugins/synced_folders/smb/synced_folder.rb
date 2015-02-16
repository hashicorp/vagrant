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
        if Vagrant::Util::Platform.windows?
          if !Vagrant::Util::Platform.windows_admin?
            raise Errors::WindowsAdminRequired if raise_error
            return false
          end

          psv = Vagrant::Util::PowerShell.version.to_i
          if psv < 3
            if raise_error
              raise Errors::PowershellVersion,
                version: psv.to_s
            end
            return false
          end

          true
        elsif Vagrant::Util::Platform.darwin?
          if Vagrant::Util::Platform.platform < 'darwin12.0'
            raise Errors::DarwinVersion
            return false
          end

          true
        else
          raise Errors::WindowsDarwinHostRequired if raise_error

          false
        end
      end

      def prepare(machine, folders, opts)
        machine.ui.output(I18n.t("vagrant_sf_smb.preparing"))

        # If we need auth information, then ask the user.
        have_auth = false
        folders.each do |id, data|
          if data[:smb_username] && data[:smb_password]
            @creds[:username] = data[:smb_username]
            @creds[:password] = data[:smb_password]
            have_auth = true
            break
          end
        end

        if !have_auth
          machine.ui.detail(I18n.t("vagrant_sf_smb.warning_password") + "\n ")
          @creds[:username] = machine.ui.ask("Username: ")
          @creds[:password] = machine.ui.ask("Password (will be hidden): ", echo: false)
        end

        if machine.env.host.capability?(:enable_smb_sharing)
          @logger.debug("Enabling SMB sharing on the host if needed")
          # Hide interactive password from logs enclosing credentials in a lambda. If
          # instead credentials have been specified in Vagrantfile, logs are less of
          # a problem.
          machine.env.host.capability(:enable_smb_sharing, machine, folders, lambda { @creds })
        end

        folders.each do |id, data|
          machine.env.host.capability(:create_smb_share, machine, id, data)
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
          candidate_ips = machine.env.host.capability(:load_host_ips)
          @logger.debug("Potential host IPs: #{candidate_ips.inspect}")
          host_ip = machine.guest.capability(
            :choose_addressable_ip_addr, candidate_ips)
          if !host_ip
            raise Errors::NoHostIPAddr
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

          # Set mount options depending on the host OS
          if Vagrant::Util::Platform.windows?
            data[:mount_options] = ["sec=ntlm"]
          elsif Vagrant::Util::Platform.darwin?
            data[:mount_options] = ["noserverino", "nounix", "sec=ntlmssp"]
          end

          machine.ui.detail(I18n.t(
            "vagrant_sf_smb.mounting_single",
            host: data[:hostpath].to_s,
            guest: data[:guestpath].to_s))
          machine.guest.capability(
            :mount_smb_shared_folder, data[:smb_id], data[:guestpath], data)
        end
      end

      def cleanup(machine, opts)
        if machine.env.host.capability?(:cleanup_smb_shares)
          @logger.debug("Cleaning up SMB shares on the host")
          machine.ui.output(I18n.t("vagrant_sf_smb.cleaning"))
          machine.env.host.capability(:cleanup_smb_shares, machine, opts)
        end
      end
    end
  end
end
