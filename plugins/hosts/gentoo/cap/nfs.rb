require 'vagrant/util/subprocess'
require 'vagrant/util/which'

module VagrantPlugins
  module HostGentoo
    module Cap
      class NFS
        def self.nfs_check_command(_env)
          if systemd?
            return "#{systemctl_path} status nfsd"
          else
            return '/etc/init.d/nfs status'
          end
        end

        def self.nfs_start_command(_env)
          if systemd?
            return "#{systemctl_path} start nfsd rpc-mountd rpcbind"
          else
            return '/etc/init.d/nfs restart'
          end
        end

        protected

        # This tests to see if systemd is used on the system. This is used
        # in newer versions of Arch, and requires a change in behavior.
        def self.systemd?
          result = Vagrant::Util::Subprocess.execute('ps', '-o', 'comm=', '1')
          result.stdout.chomp == 'systemd'
        end

        def self.systemctl_path
          path = Vagrant::Util::Which.which('systemctl')
          return path if path

          folders = ['/usr/bin', '/usr/sbin']
          folders.each do |folder|
            path = "#{folder}/systemctl"
            return path if File.file?(path)
          end
        end
      end
    end
  end
end
