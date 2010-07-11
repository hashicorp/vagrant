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
        def initialize(app,env)
          @app = app
          @env = env

          verify_host
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
