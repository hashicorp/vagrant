require "log4r"

require "vagrant/action/builtin/mixin_synced_folders"

module VagrantPlugins
  module DockerProvider
    module Action
      # This action disables the synced folders we created.
      class HostMachineSyncFoldersDisable
        include Vagrant::Action::Builtin::MixinSyncedFolders

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::docker::hostmachine")
        end

        def call(env)
          return @app.call(env) if !env[:machine].provider.host_vm?

          # Read our random ID for this instance
          id_path   = env[:machine].data_dir.join("host_machine_sfid")
          return @app.call(env) if !id_path.file?
          host_sfid = id_path.read.chomp

          host_machine = env[:machine].provider.host_vm

          @app.call(env)

          begin
            env[:machine].provider.host_vm_lock do
              setup_synced_folders(host_machine, host_sfid, env)
            end
          rescue Vagrant::Errors::EnvironmentLockedError
            sleep 1
            retry
          end
        end

        protected

        def setup_synced_folders(host_machine, host_sfid, env)
          to_disable = []

          # Read the existing folders that are setup
          existing_folders = synced_folders(host_machine, cached: true)
          if existing_folders
            existing_folders.each do |impl, fs|
              fs.each do |id, data|
                if data[:docker_host_sfid] == host_sfid
                  to_disable << id
                end
              end
            end
          end

          # Nothing to do if we have no bad folders
          return if to_disable.empty?

          # Create a UI for this machine that stays at the detail level
          proxy_ui = host_machine.ui.dup
          proxy_ui.opts[:bold] = false
          proxy_ui.opts[:prefix_spaces] = true
          proxy_ui.opts[:target] = env[:machine].name.to_s

          env[:machine].ui.output(I18n.t(
            "docker_provider.host_machine_disabling_folders"))
          host_machine.with_ui(proxy_ui) do
            action_env = {
              synced_folders_cached: true,
              synced_folders_disable: to_disable,
            }

            begin
              host_machine.action(:sync_folders, action_env)
            rescue Vagrant::Errors::MachineActionLockedError
              sleep 1
              retry
            rescue Vagrant::Errors::UnimplementedProviderAction
              callable = Vagrant::Action::Builder.new
              callable.use Vagrant::Action::Builtin::SyncedFolders
              host_machine.action_raw(:sync_folders, callable, action_env)
            end
          end
        end
      end
    end
  end
end
