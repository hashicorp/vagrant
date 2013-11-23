require 'fileutils'
require 'zlib'

require "vagrant/util/platform"

module VagrantPlugins
  module SyncedFolderNFS
    # This synced folder requires that two keys be set on the environment
    # within the middleware sequence:
    #
    #   - `:nfs_host_ip` - The IP of where to mount the NFS folder from.
    #   - `:nfs_machine_ip` - The IP of the machine where the NFS folder
    #     will be mounted.
    #
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      def usable?(machine)
        # NFS is always available
        true
      end

      def prepare(machine, folders, opts)
        # Nothing is necessary to do before VM boot.
      end

      def enable(machine, folders, nfsopts)
        raise Errors::NFSNoHostIP if !nfsopts[:nfs_host_ip]
        raise Errors::NFSNoGuestIP if !nfsopts[:nfs_machine_ip]

        machine_ip = nfsopts[:nfs_machine_ip]
        machine_ip = [machine_ip] if !machine_ip.is_a?(Array)

        # Prepare the folder, this means setting up various options
        # and such on the folder itself.
        folders.each { |id, opts| prepare_folder(machine, opts) }

        # Export the folders
        machine.ui.info I18n.t("vagrant.actions.vm.nfs.exporting")
        machine.env.host.nfs_export(machine.id, machine_ip, folders)

        # Mount
        machine.ui.info I18n.t("vagrant.actions.vm.nfs.mounting")

        # Only mount folders that have a guest path specified.
        mount_folders = {}
        folders.each do |id, opts|
          mount_folders[id] = opts.dup if opts[:guestpath]
        end

        # Mount them!
        machine.guest.capability(
          :mount_nfs_folder, nfsopts[:nfs_host_ip], mount_folders)
      end

      protected

      def prepare_folder(machine, opts)
        opts[:map_uid] = prepare_permission(machine, :uid, opts)
        opts[:map_gid] = prepare_permission(machine, :gid, opts)
        opts[:nfs_version] ||= 3

        # We use a CRC32 to generate a 32-bit checksum so that the
        # fsid is compatible with both old and new kernels.
        opts[:uuid] = Zlib.crc32(opts[:hostpath]).to_s
      end

      # Prepares the UID/GID settings for a single folder.
      def prepare_permission(machine, perm, opts)
        key = "map_#{perm}".to_sym
        return nil if opts.has_key?(key) && opts[key].nil?

        # The options on the hash get priority, then the default
        # values
        value = opts.has_key?(key) ? opts[key] : machine.config.nfs.send(key)
        return value if value != :auto

        # Get UID/GID from folder if we've made it this far
        # (value == :auto)
        stat = File.stat(opts[:hostpath])
        return stat.send(perm)
      end
    end
  end
end
