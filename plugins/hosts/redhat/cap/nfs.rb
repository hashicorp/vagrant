require "pathname"

module VagrantPlugins
  module HostRedHat
    module Cap
      class NFS
        def self.nfs_check_command(env)
          if Vagrant::Util::Platform.systemd?
            "systemctl status --no-pager nfs-server.service"
          else
            "#{nfs_server_binary} status"
          end
        end

        def self.nfs_start_command(env)
          if Vagrant::Util::Platform.systemd?
            "systemctl start nfs-server.service"
          else
            "#{nfs_server_binary} start"
          end
        end

        protected

        def self.nfs_server_binary
          nfs_server_binary = "/etc/init.d/nfs"

          # On Fedora 16+, systemd replaced init.d, so we have to use the
          # proper NFS binary. This checks to see if we need to do that.
          release_file = Pathname.new("/etc/redhat-release")
          begin
            release_file.open("r:ISO-8859-1:UTF-8") do |f|
              match = /(Red Hat|CentOS|Fedora).* release ([0-9]+)/.match(f.gets)
              if match
                distribution = match[1]
                version_number = match[2].to_i
                if (distribution =~ /Fedora/ && version_number >= 16) ||
                   (distribution =~ /Red Hat|CentOS/ && version_number >= 7)
                  # "service nfs-server" will redirect properly to systemctl
                  # when "service nfs-server restart" is called.
                  nfs_server_binary = "/usr/sbin/service nfs-server"
                end
              end
            end
          rescue Errno::ENOENT
            # File doesn't exist, not a big deal, assume we're on a
            # lower version.
          end

          nfs_server_binary
        end
      end
    end
  end
end
