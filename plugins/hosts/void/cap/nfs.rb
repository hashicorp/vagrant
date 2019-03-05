module VagrantPlugins
  module HostVoid
    module Cap
      class NFS
        def self.nfs_check_command(env)
          "sudo /usr/bin/sv status nfs-server"
        end

        def self.nfs_start_command(env)
          <<-EOF
            /usr/bin/ln -s /etc/sv/statd      /var/service/ && \
            /usr/bin/ln -s /etc/sv/rpcbind    /var/service/ && \
            /usr/bin/ln -s /etc/sv/nfs-server /var/service/
          EOF
        end

        def self.nfs_installed(env)
          result = Vagrant::Util::Subprocess.execute("/usr/bin/xbps-query", "nfs-utils")
          result.exit_code == 0
        end
      end
    end
  end
end
