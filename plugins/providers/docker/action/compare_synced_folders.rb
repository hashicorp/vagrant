require "vagrant/action/builtin/mixin_synced_folders"

module VagrantPlugins
  module DockerProvider
    module Action
      class CompareSyncedFolders
        include Vagrant::Action::Builtin::MixinSyncedFolders

        def initialize(app, env)
          @app = app
        end

        def call(env)
          machine = env[:machine]

          # Get the synced folders that are cached, and those that aren't
          cached = synced_folders(machine, cached: true)
          fresh  = synced_folders(machine)

          # Build up a mapping of existing setup synced folders
          existing = {}
          cached.each do |_, fs|
            fs.each do |_, data|
              existing[data[:guestpath]] = data[:hostpath]
            end
          end

          # Remove the matching folders, and build up non-matching or
          # new synced folders.
          invalids = {}
          fresh.each do |_, fs|
            fs.each do |_, data|
              invalid = false
              old     = existing.delete(data[:guestpath])
              if !old
                invalid = true
              else
                old = File.expand_path(old)
              end

              if !invalid && old
                invalid = true if old != File.expand_path(data[:hostpath])
              end

              if invalid
                invalids[File.expand_path(data[:guestpath])] = File.expand_path(data[:hostpath])
              end
            end
          end

          # If we have invalid entries, these are changed or new entries.
          # If we have existing entries, then we removed some entries.
          if !invalids.empty? || !existing.empty?
            machine.ui.warn(I18n.t("docker_provider.synced_folders_changed"))
          end

          @app.call(env)
        end
      end
    end
  end
end
