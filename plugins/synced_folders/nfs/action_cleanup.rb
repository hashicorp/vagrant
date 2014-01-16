require "log4r"

module VagrantPlugins
  module SyncedFolderNFS
    class ActionCleanup
      def initialize(app, env)
        @app    = app
        @logger = Log4r::Logger.new("vagrant::synced_folders::nfs")
      end

      def call(env)
        if !env[:nfs_valid_ids]
          @logger.warn("nfs_valid_ids not set, cleanup cannot occur")
          return @app.call(env)
        end

        if !env[:machine].env.host.capability?(:nfs_prune)
          @logger.info("Host doesn't support pruning NFS. Skipping.")
          return @app.call(env)
        end

        @logger.info("NFS pruning. Valid IDs: #{env[:nfs_valid_ids].inspect}")
        env[:machine].env.host.capability(
          :nfs_prune, env[:machine].ui, env[:nfs_valid_ids])
        @app.call(env)
      end
    end
  end
end
