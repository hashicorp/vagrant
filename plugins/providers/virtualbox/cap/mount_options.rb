require_relative "../../../synced_folders/unix_mount_helpers"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module MountOptions
        extend VagrantPlugins::SyncedFolder::UnixMountHelpers

        VB_MOUNT_TYPE = "vboxsf".freeze

        # Returns mount options for a virtual box synced folder
        #
        # @param [Machine] machine
        # @param [String] name of mount
        # @param [String] path of mount on guest
        # @param [Hash] hash of mount options 
        def self.mount_options(machine, name, guest_path, options)
          mount_options = options.fetch(:mount_options, [])
          detected_ids = detect_owner_group_ids(machine, guest_path, mount_options, options)
          mount_uid = detected_ids[:uid]
          mount_gid = detected_ids[:gid]

          mount_options << "uid=#{mount_uid}"
          mount_options << "gid=#{mount_gid}"
          mount_options = mount_options.join(',')
          return mount_options, mount_uid, mount_gid
        end

        def self.mount_type(machine)
          return VB_MOUNT_TYPE
        end
      end
    end
  end
end
