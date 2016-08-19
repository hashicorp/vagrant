require 'fileutils'
require 'thread'
require 'zlib'

require "log4r"

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
      @@lock = Mutex.new

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::synced_folders::nfs")
      end

      def usable?(machine, raise_error=false)
        # If the machine explicitly said NFS is not supported, then
        # it isn't supported.
        if !machine.config.nfs.functional
          return false
        end
        return true if machine.env.host.capability(:nfs_installed)
        return false if !raise_error
        raise Vagrant::Errors::NFSNotSupported
      end

      def prepare(machine, folders, opts)
        # Nothing is necessary to do before VM boot.
      end

      def enable(machine, folders, nfsopts)
        raise Vagrant::Errors::NFSNoHostIP if !nfsopts[:nfs_host_ip]
        raise Vagrant::Errors::NFSNoGuestIP if !nfsopts[:nfs_machine_ip]

        if machine.config.nfs.verify_installed
          if machine.guest.capability?(:nfs_client_installed)
            installed = machine.guest.capability(:nfs_client_installed)
            if !installed
              can_install = machine.guest.capability?(:nfs_client_install)
              raise Vagrant::Errors::NFSClientNotInstalledInGuest if !can_install
              machine.ui.info I18n.t("vagrant.actions.vm.nfs.installing")
              machine.guest.capability(:nfs_client_install)
            end
          end
        end

        machine_ip = nfsopts[:nfs_machine_ip]
        machine_ip = [machine_ip] if !machine_ip.is_a?(Array)

        # Prepare the folder, this means setting up various options
        # and such on the folder itself.
        folders.each { |id, opts| prepare_folder(machine, opts) }

        # Determine what folders we'll export
        export_folders = folders.dup
        export_folders.keys.each do |id|
          opts = export_folders[id]
          if opts.key?(:nfs_export) && !opts[:nfs_export]
            export_folders.delete(id)
          end
        end

        # Update the exports when there are actually exports [GH-4148]
        if !export_folders.empty?
          # Export the folders. We do this with a class-wide lock because
          # NFS exporting often requires sudo privilege and we don't want
          # overlapping input requests. [GH-2680]
          @@lock.synchronize do
            begin
              machine.env.lock("nfs-export") do
                machine.ui.info I18n.t("vagrant.actions.vm.nfs.exporting")
                machine.env.host.capability(
                  :nfs_export,
                  machine.ui, machine.id, machine_ip, export_folders)
              end
            rescue Vagrant::Errors::EnvironmentLockedError
              sleep 1
              retry
            end
          end
        end

        # Mount
        machine.ui.info I18n.t("vagrant.actions.vm.nfs.mounting")

        # Only mount folders that have a guest path specified.
        mount_folders = {}
        folders.each do |id, opts|
          mount_folders[id] = opts.dup if opts[:guestpath]
        end

        # Mount them!
        if machine.guest.capability?(:nfs_pre)
          machine.guest.capability(:nfs_pre)
        end

        machine.guest.capability(:mount_nfs_folder,
          nfsopts[:nfs_host_ip], mount_folders)

        if machine.guest.capability?(:nfs_post)
          machine.guest.capability(:nfs_post)
        end
      end

      def cleanup(machine, opts)
        ids = opts[:nfs_valid_ids]
        raise Vagrant::Errors::NFSNoValidIds if !ids

        # Prune any of the unused machines
        @logger.info("NFS pruning. Valid IDs: #{ids.inspect}")
        machine.env.host.capability(:nfs_prune, machine.ui, ids)
      end

      protected

      def prepare_folder(machine, opts)
        opts[:map_uid] = prepare_permission(machine, :uid, opts)
        opts[:map_gid] = prepare_permission(machine, :gid, opts)
        opts[:nfs_udp] = true if !opts.key?(:nfs_udp)
        opts[:nfs_version] ||= 3


        if opts[:nfs_version].to_s.start_with?('4') && opts[:nfs_udp]
          machine.ui.info I18n.t("vagrant.actions.vm.nfs.v4_with_udp_warning")
        end

        # We use a CRC32 to generate a 32-bit checksum so that the
        # fsid is compatible with both old and new kernels.
        opts[:uuid] = Zlib.crc32(opts[:hostpath]).to_s
      end

      # Prepares the UID/GID settings for a single folder.
      def prepare_permission(machine, perm, opts)
        key = "map_#{perm}".to_sym
        return nil if opts.key?(key) && opts[key].nil?

        # The options on the hash get priority, then the default
        # values
        value = opts.key?(key) ? opts[key] : machine.config.nfs.send(key)
        return value if value != :auto

        # Get UID/GID from folder if we've made it this far
        # (value == :auto)
        stat = File.stat(opts[:hostpath])
        return stat.send(perm)
      end
    end
  end
end
