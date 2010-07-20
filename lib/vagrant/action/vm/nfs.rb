require File.join(File.dirname(__FILE__), 'nfs_helpers')

module Vagrant
  class Action
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
        include ExceptionCatcher
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

          return if env.error?

          @app.call(env)

          mount_folders if !folders.empty? && !env.error?
          clear_nfs_exports(env) if env.error?
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
          @folders = @env["config"].vm.shared_folders.inject({}) do |acc, data|
            key, opts = data

            if opts[:nfs]
              # Duplicate the options, set the hostpath, and set disabled on the original
              # options so the ShareFolders middleware doesn't try to mount it.
              acc[key] = opts.dup
              acc[key][:hostpath] = File.expand_path(opts[:hostpath], @env.env.root_path)
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
          value = opts[key] || @env["config"].nfs.send(key)
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
          @env.logger.info "Exporting NFS shared folders..."

          catch_action_exception(@env) do
            @env["host"].nfs_export(guest_ip, folders)
          end
        end

        # Uses the system class to mount the NFS folders.
        def mount_folders
          @env.logger.info "Mounting NFS shared folders..."

          catch_action_exception(@env) do
            @env["vm"].system.mount_nfs(host_ip, folders)
          end
        end

        # Returns the IP address of the first host only network adapter
        #
        # @return [String]
        def host_ip
          interface = @env["vm"].vm.network_adapters.find do |adapter|
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
          @env["config"].vm.network_options[1][:ip]
        end

        # Checks if there are any NFS enabled shared folders.
        def nfs_enabled?
          @env["config"].vm.shared_folders.each do |key, opts|
            return true if opts[:nfs]
          end

          false
        end

        # Verifies that the host is set and supports NFS.
        def verify_settings
          return @env.error!(:nfs_host_required) if @env["host"].nil?
          return @env.error!(:nfs_not_supported) if !@env["host"].nfs?
          return @env.error!(:nfs_no_host_network) if @env["config"].vm.network_options.empty?
        end
      end
    end
  end
end
