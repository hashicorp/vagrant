module VagrantPlugins
  module DockerProvider
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      def usable?(machine)
        # These synced folders only work if the provider is Docker
        machine.provider_name == :docker
      end

      def prepare(machine, folders, _opts)
        # FIXME: Check whether the container has already been created with
        #        different synced folders and let the user know about it
        folders.each do |id, data|
          host_path  = File.expand_path(data[:hostpath], machine.env.root_path)
          guest_path = data[:guestpath]
          machine.provider_config.volumes << "#{host_path}:#{guest_path}"
        end
      end
    end
  end
end
