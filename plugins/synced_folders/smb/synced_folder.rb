require "digest/md5"
require "json"

require "log4r"

require "vagrant/util/platform"
require "vagrant/util/powershell"

require_relative "errors"

module VagrantPlugins
  module SyncedFolderSMB
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)

      # Maximum number of times to retry requesting username/password
      CREDENTIAL_RETRY_MAX = 5

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::synced_folders::smb")
      end

      def usable?(machine, raise_error=false)
        # If the machine explicitly states SMB is not supported, then
        # believe it
        return false if !machine.config.smb.functional
        return true if machine.env.host.capability?(:smb_installed) &&
          machine.env.host.capability(:smb_installed)
        return false if !raise_error
        raise Errors::SMBNotSupported
      end

      def prepare(machine, folders, opts)
        machine.ui.output(I18n.t("vagrant_sf_smb.preparing"))

        smb_username = smb_password = nil

        # If we need auth information, then ask the user.
        have_auth = false
        folders.each do |id, data|
          smb_username = data[:smb_username] if data[:smb_username]
          smb_password = data[:smb_password] if data[:smb_password]
          if smb_username && smb_password
            have_auth = true
            break
          end
        end

        modify_username = false
        if !have_auth
          machine.ui.detail(I18n.t("vagrant_sf_smb.warning_password") + "\n ")
          retries = 0
          while retries < CREDENTIAL_RETRY_MAX do
            if smb_username
              username = machine.ui.ask("Username (#{smb_username}): ")
              smb_username = username if username != ""
              modify_username = true
            else
              smb_username = machine.ui.ask("Username (user[@domain]): ")
            end

            smb_password = machine.ui.ask("Password (will be hidden): ", echo: false)
            auth_success = true

            if machine.env.host.capability?(:smb_validate_password)
              Vagrant::Util::CredentialScrubber.sensitive(smb_password)
              auth_success = machine.env.host.capability(:smb_validate_password,
                machine, smb_username, smb_password)
            end

            break if auth_success
            machine.ui.output(I18n.t("vagrant_sf_smb.incorrect_credentials") + "\n ")
            retries += 1
          end

          if retries >= CREDENTIAL_RETRY_MAX
            raise Errors::CredentialsRequestError
          end
        end

        # Check if this host can start and SMB service
        if machine.env.host.capability?(:smb_start)
          machine.env.host.capability(:smb_start)
        end

        folders.each do |id, data|
          if modify_username
            # Only override original username if user requests to
            data[:smb_username] = smb_username
          else
            data[:smb_username] ||= smb_username
          end
          data[:smb_password] ||= smb_password

          # Register password as sensitive
          Vagrant::Util::CredentialScrubber.sensitive(data[:smb_password])
        end

        machine.env.host.capability(:smb_prepare, machine, folders, opts)
      end

      def enable(machine, folders, opts)
        machine.ui.output(I18n.t("vagrant_sf_smb.mounting"))

        # Make sure that this machine knows this dance
        if !machine.guest.capability?(:mount_smb_shared_folder)
          raise Vagrant::Errors::GuestCapabilityNotFound,
            cap: "mount_smb_shared_folder",
            guest: machine.guest.name.to_s
        end

        # Setup if we have it
        if machine.guest.capability?(:smb_install)
          machine.guest.capability(:smb_install)
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
          candidate_ips = machine.env.host.capability(:configured_ip_addresses)
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
          data[:smb_host] ||= host_ip

          # Default the owner/group of the folder to the SSH user
          data[:owner] ||= ssh_info[:username]
          data[:group] ||= ssh_info[:username]

          machine.ui.detail(I18n.t(
            "vagrant_sf_smb.mounting_single",
            host: data[:hostpath].to_s,
            guest: data[:guestpath].to_s))
          machine.guest.capability(
            :mount_smb_shared_folder, data[:smb_id], data[:guestpath], data)

          clean_folder_configuration(data)
        end
      end

      # Nothing to do here but ensure folder options are scrubbed
      def disable(machine, folders, opts)
        folders.each do |_, data|
          clean_folder_configuration(data)
        end
      end

      def cleanup(machine, opts)
        if machine.env.host.capability?(:smb_cleanup)
          machine.env.host.capability(:smb_cleanup, machine, opts)
        end
      end

      protected

      # Remove data that should not be persisted within folder
      # specific configuration
      #
      # @param [Hash] data Folder configuration
      def clean_folder_configuration(data)
        return if !data.is_a?(Hash)
        data.delete(:smb_password)
        nil
      end
    end
  end
end
