module VagrantPlugins
  module DockerProvider
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      def usable?(machine, raise_error=false)
        # These synced folders only work if the provider is Docker
        if machine.provider_name != :docker
          if raise_error
            raise Errors::SyncedFolderNonDocker,
              provider: machine.provider_name.to_s
          end

          return false
        end

        true
      end

      def prepare(machine, folders, _opts)
        # FIXME: Check whether the container has already been created with
        #        different synced folders and let the user know about it
        folders.each do |id, data|
          host_path  = data[:hostpath]
          guest_path = data[:guestpath]
          machine.provider_config.volumes << "#{host_path}:#{guest_path}"
        end
      end
    end
  end
end
