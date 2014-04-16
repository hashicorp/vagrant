require "digest/md5"

require "log4r"

require "vagrant/action/builtin/mixin_synced_folders"

module VagrantPlugins
  module DockerProvider
    module Action
      # This action is responsible for creating the host machine if
      # we need to. The host machine is where Docker containers will
      # live.
      class HostMachineSyncFolders
        include Vagrant::Action::Builtin::MixinSyncedFolders

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::docker::hostmachine")
        end

        def call(env)
          return @app.call(env) if !env[:machine].provider.host_vm?

          host_machine = env[:machine].provider.host_vm

          # Grab a process-level lock on the data directory of this VM
          # so that we only try to modify this one at a time.
          hash = Digest::MD5.hexdigest(host_machine.data_dir.to_s)
          begin
            env[:machine].env.lock(hash) do
              setup_synced_folders(host_machine, env)
            end
          rescue Vagrant::Errors::EnvironmentLockedError
            sleep 1
            retry
          end

          @app.call(env)
        end

        protected

        def setup_synced_folders(host_machine, env)
          # Create a UI for this machine that stays at the detail level
          proxy_ui = host_machine.ui.dup
          proxy_ui.opts[:bold] = false
          proxy_ui.opts[:prefix_spaces] = true
          proxy_ui.opts[:target] = env[:machine].name.to_s

          # Read the existing folders that are setup
          existing_folders = synced_folders(host_machine, cached: true)
          existing_ids = {}
          if existing_folders
            existing_folders.each do |impl, fs|
              fs.each do |_name, data|
                if data[:docker_sfid]
                  existing_ids[data[:docker_sfid]] = data
                end
              end
            end
          end

          # Sync some folders so that our volumes work later.
          new_config  = VagrantPlugins::Kernel_V2::VMConfig.new
          our_folders = synced_folders(env[:machine])
          our_folders.each do |type, folders|
            folders.each do |id, data|
              data = data.dup

              if type == :docker
                # We don't use the Docker type explicitly on the host VM
                data.delete(:type)
              end

              # Generate an ID that is deterministic based on our machine
              # and Vagrantfile path...
              id = Digest::MD5.hexdigest(
                "#{env[:machine].env.root_path}#{env[:machine].name}")

              # Generate a new guestpath
              data[:docker_guestpath] = data[:guestpath]
              data[:docker_sfid] = id
              data[:guestpath] = "/mnt/docker_#{Time.now.to_i}_#{rand(100000)}"
              data[:id] = id[0...6] + rand(10000).to_s

              # Add this synced folder onto the new config if we haven't
              # already shared it before.
              if !existing_ids.has_key?(id)
                new_config.synced_folder(
                  data[:hostpath],
                  data[:guestpath],
                  data)
              else
                # We already have the folder, so just load its data
                data = existing_ids[id]
              end

              # Remove from our machine
              env[:machine].config.vm.synced_folders.delete(id)

              # Add the "fixed" folder to our machine
              data = data.merge({
                hostpath_exact: true,
                type: :docker,
              })
              env[:machine].config.vm.synced_folder(
                data[:guestpath],
                data[:docker_guestpath],
                data)
            end
          end

          if !new_config.synced_folders.empty?
            # Sync the folders!
            env[:machine].ui.output(I18n.t(
              "docker_provider.host_machine_syncing_folders"))
            host_machine.with_ui(proxy_ui) do
              action_env = { synced_folders_config: new_config }
              begin
                host_machine.action(:sync_folders, action_env)
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
end
