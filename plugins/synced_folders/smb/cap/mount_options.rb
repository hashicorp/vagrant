require_relative "../../unix_mount_helpers"

module VagrantPlugins
  module SyncedFolderSMB
    module Cap
      module MountOptions
        extend VagrantPlugins::SyncedFolder::UnixMountHelpers

        MOUNT_TYPE = "cifs".freeze

        # Returns mount options for a smb synced folder
        #
        # @param [Machine] machine
        # @param [String] name of mount
        # @param [String] path of mount on guest
        # @param [Hash] hash of mount options 
        def self.mount_options(machine, name, guest_path, options)
          mount_options = options.fetch(:mount_options, [])
          options[:smb_id] ||= name
          detected_ids = detect_owner_group_ids(machine, guest_path, mount_options, options)
          mount_uid = detected_ids[:uid]
          mount_gid = detected_ids[:gid]

          mnt_opts = []
          if machine.env.host.capability?(:smb_mount_options)
            mnt_opts += machine.env.host.capability(:smb_mount_options)
          else
            mnt_opts << "sec=ntlmssp"
          end

          mnt_opts << "credentials=/etc/smb_creds_#{options[:smb_id]}"
          mnt_opts << "uid=#{mount_uid}"
          mnt_opts << "gid=#{mount_gid}"
          if !ENV['VAGRANT_DISABLE_SMBMFSYMLINKS']
            mnt_opts << "mfsymlinks"
          end
          mnt_opts << "_netdev"
          mnt_opts = merge_mount_options(mnt_opts, options[:mount_options] || [])

          mount_options = mnt_opts.join(",")
          return mount_options, mount_uid, mount_gid
        end

        def self.mount_type(machine)
          return  MOUNT_TYPE
        end

        def self.mount_name(machine, data)
          data[:smb_host] ||= machine.guest.capability(
            :choose_addressable_ip_addr, candidate_ips)
          "//#{data[:smb_host]}/#{data[:smb_id]}"
        end
      end
    end
  end
end
