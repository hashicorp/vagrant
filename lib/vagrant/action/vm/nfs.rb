require File.expand_path("../nfs_helpers", __FILE__)

module Vagrant
  module Action
    module VM
      # Enables NFS based shared folders. `nfsd` must already be installed
      # on the host machine, and NFS client must already be installed on
      # the guest machine.
      #
      # This is a two part process:
      #
      #   1. Adds an entry to `/etc/exports` on the host machine using
      #      the host class to export the proper folder to the proper
      #      machine.
      #   2. After boot, runs `mount` on the guest to mount the shared
      #      folder.
      #
      class NFS
        include NFSHelpers

        def initialize(app,env)
          @app = app
          @env = env

          verify_settings if nfs_enabled?
        end

        def call(env)
          @env = env

          extract_folders

          if !folders.empty?
            prepare_folders
            clear_nfs_exports(env)
            export_folders
          end

          @app.call(env)

          mount_folders if !folders.empty?
        end

        def recover(env)
          clear_nfs_exports(env) if env[:vm].created?
        end

        # Returns the folders which are to be synced via NFS.
        def folders
          @folders ||= {}
        end

        # Removes the NFS enabled shared folders from the configuration,
        # so they will no longer be mounted by the actual shared folder
        # task.
        def extract_folders
          # Load the NFS enabled shared folders
          @folders = @env[:vm].config.vm.shared_folders.inject({}) do |acc, data|
            key, opts = data

            if opts[:nfs]
              # Duplicate the options, set the hostpath, and set disabled on the original
              # options so the ShareFolders middleware doesn't try to mount it.
              acc[key] = opts.dup
              acc[key][:hostpath] = File.expand_path(opts[:hostpath], @env[:root_path])
              opts[:disabled] = true
            end

            acc
          end
        end

        # Prepares the settings for the NFS folders, such as setting the
        # options on the NFS folders.
        def prepare_folders
          @folders = @folders.inject({}) do |acc, data|
            key, opts = data
            opts[:nfs] = {} if !opts.is_a?(Hash)
            opts[:map_uid] = prepare_permission(:uid, opts)
            opts[:map_gid] = prepare_permission(:gid, opts)

            acc[key] = opts
            acc
          end
        end

        # Prepares the UID/GID settings for a single folder.
        def prepare_permission(perm, opts)
          key = "map_#{perm}".to_sym
          return nil if opts.has_key?(key) && opts[key].nil?

          # The options on the hash get priority, then the default
          # values
          value = opts.has_key?(key) ? opts[key] : @env[:vm].config.nfs.send(key)
          return value if value != :auto

          # Get UID/GID from folder if we've made it this far
          # (value == :auto)
          stat = File.stat(opts[:hostpath])
          return stat.send(perm)
        end

        # Uses the host class to export the folders via NFS. This typically
        # involves adding a line to `/etc/exports` for this VM, but it is
        # up to the host class to define the specific behavior.
        def export_folders
          @env[:ui].info I18n.t("vagrant.actions.vm.nfs.exporting")

          @env[:host].nfs_export(@env[:vm].uuid, guest_ip, folders)
        end

        # Uses the system class to mount the NFS folders.
        def mount_folders
          @env[:ui].info I18n.t("vagrant.actions.vm.nfs.mounting")

          # Only mount the folders which have a guest path specified
          am_folders = folders.select { |name, folder| folder[:guestpath] }
          am_folders = Hash[*am_folders.flatten] if am_folders.is_a?(Array)
          @env[:vm].guest.mount_nfs(host_ip, Hash[am_folders])
        end

        # Returns the IP address of the first host only network adapter
        #
        # @return [String]
        def host_ip
          interface = @env[:vm].vm.network_adapters.find do |adapter|
            adapter.host_interface_object
          end

          return nil if !interface
          interface.host_interface_object.ip_address
        end

        # Returns the IP address of the guest by looking at the first
        # enabled host only network.
        #
        # @return [String]
        def guest_ip
          @env[:vm].config.vm.network_options[1][:ip]
        end

        # Checks if there are any NFS enabled shared folders.
        def nfs_enabled?
          @env[:vm].config.vm.shared_folders.each do |key, opts|
            return true if opts[:nfs]
          end

          false
        end

        # Verifies that the host is set and supports NFS.
        def verify_settings
          raise Errors::NFSHostRequired if @env[:host].nil?
          raise Errors::NFSNotSupported if !@env[:host].nfs?
          raise Errors::NFSNoHostNetwork if @env[:vm].config.vm.network_options.empty?
        end
      end
    end
  end
end
