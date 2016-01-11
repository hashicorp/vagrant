require "log4r"

require "digest/md5"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PrepareCloneSnapshot
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::prepare_clone")
        end

        def call(env)
          if !env[:clone_id]
            @logger.info("no clone master, not preparing clone snapshot")
            return @app.call(env)
          end

          # If we're not doing a linked clone, snapshots don't matter
          if !env[:machine].provider_config.linked_clone
            return @app.call(env)
          end

          # We lock so that we don't snapshot in parallel
          lock_key = Digest::MD5.hexdigest("#{env[:clone_id]}-snapshot")
          env[:machine].env.lock(lock_key, retry: true) do
            prepare_snapshot(env)
          end

          # Continue
          @app.call(env)
        end

        protected

        def prepare_snapshot(env)
          name = env[:machine].provider_config.linked_clone_snapshot
          name_set = !!name
          name = "base" if !name
          env[:clone_snapshot] = name

          # Get the snapshots. We're done if it already exists
          snapshots = env[:machine].provider.driver.list_snapshots(env[:clone_id])
          if snapshots.include?(name)
            @logger.info("clone snapshot already exists, doing nothing")
            return
          end

          # If they asked for a specific snapshot, it is an error
          if name_set
            # TODO: Error
          end

          @logger.info("Creating base snapshot for master VM.")
          env[:machine].provider.driver.create_snapshot(
            env[:clone_id], name) do |progress|
              env[:ui].clear_line
              env[:ui].report_progress(progress, 100, false)
          end
        end
      end
    end
  end
end
