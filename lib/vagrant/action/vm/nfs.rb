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
        attr_reader :folders

        def initialize(app,env)
          @app = app
          @env = env

          verify_host
        end

        def call(env)
          @env = env

          extract_folders
          export_folders

          @app.call(env)
        end

        # Removes the NFS enabled shared folders from the configuration,
        # so they will no longer be mounted by the actual shared folder
        # task.
        def extract_folders
          # Load the NFS enabled shared folders
          @folders = @env["config"].vm.shared_folders.inject({}) do |acc, data|
            key, opts = data
            acc[key] = opts if opts[:nfs]
            acc
          end

          # Delete them from the original configuration so they aren't
          # mounted by the ShareFolders middleware
          @folders.each do |key, opts|
            @env["config"].vm.shared_folders.delete(key)
          end
        end

        # Uses the host class to export the folders via NFS. This typically
        # involves adding a line to `/etc/exports` for this VM, but it is
        # up to the host class to define the specific behavior.
        def export_folders
        end

        # Verifies that the host is set and supports NFS.
        def verify_host
          return @env.error!(:nfs_host_required) if @env["host"].nil?
          return @env.error!(:nfs_not_supported) if !@env["host"].nfs?
        end
      end
    end
  end
end
