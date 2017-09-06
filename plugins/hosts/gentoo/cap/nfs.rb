require "vagrant/util/subprocess"
require "vagrant/util/which"

module VagrantPlugins
  module HostGentoo
    module Cap
      class NFS
        def self.nfs_check_command(env)
          if Vagrant::Util::Platform.systemd?
            "#{systemctl_path} status --no-pager nfs-server.service"
          else
            "/etc/init.d/nfs status"
          end
        end

        def self.nfs_start_command(env)
          if Vagrant::Util::Platform.systemd?
            "#{systemctl_path} start rpcbind nfs-server.service"
          else
            "/etc/init.d/nfs restart"
          end
        end

        protected

        def self.systemctl_path
          path = Vagrant::Util::Which.which("systemctl")
          return path if path

          folders = ["/usr/bin", "/usr/sbin"]
          folders.each do |folder|
            path = "#{folder}/systemctl"
            return path if File.file?(path)
          end
        end
      end
    end
  end
end
