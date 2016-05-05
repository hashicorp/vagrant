require "log4r"

module VagrantPlugins
  module SyncedFolderSMB
    class ActionCleanup
      def initialize(app, env)
        @app    = app
        @logger = Log4r::Logger.new("vagrant::synced_folders::smb")
      end

      def call(env)
        @logger.info("SMB pruning. Removing shares for ID: #{env[:machine].id}")
        script_list_path =  "/usr/bin/net usershare list"
        script_delete_path =  "/usr/bin/net usershare delete"
        share_list = `"#{script_list_path} #{Digest::MD5.hexdigest(env[:machine].id)}"`
        share_list.each_line{|s|
          @logger.debug(`"#{script_delete_path} #{s}"`)
        }

        @app.call(env)
      end
    end
  end
end
