require "pathname"

module VagrantPlugins
  module HostRedHat
    module Cap
      class NFS
        def self.nfs_check_command(env)
          "#{nfs_server_binary} status"
        end

        def self.nfs_start_command(env)
          "#{nfs_server_binary} start"
        end

        protected

        def self.nfs_server_binary
          nfs_server_binary = "/etc/init.d/nfs"

          # On Fedora 16+, systemd replaced init.d, so we have to use the
          # proper NFS binary. This checks to see if we need to do that.
          release_file = Pathname.new("/etc/redhat-release")
          begin
            release_file.open("r:ISO-8859-1:UTF-8") do |f|
              fedora_match = /Fedora.* release ([0-9]+)/.match(f.gets)
              if fedora_match
                version_number = fedora_match[1].to_i
                if version_number >= 16
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
