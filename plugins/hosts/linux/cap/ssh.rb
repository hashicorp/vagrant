module VagrantPlugins
  module HostLinux
    module Cap
      class SSH
        # Set the ownership and permissions for SSH
        # private key
        #
        # @param [Vagrant::Environment] env
        # @param [Pathname] key_path
        def self.set_ssh_key_permissions(env, key_path)
          key_path.chmod(0600)
        end
      end
    end
  end
end
