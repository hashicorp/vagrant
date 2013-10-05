require "pathname"

require "vagrant"

require Vagrant.source_root.join("plugins/hosts/linux/host")

module VagrantPlugins
  module HostRedHat
    class Host < VagrantPlugins::HostLinux::Host
      def self.match?
        release_file = Pathname.new("/etc/redhat-release")

        if release_file.exist?
          release_file.open("r:ISO-8859-1:UTF-8") do |f|
            contents = f.gets
            return true if contents =~ /^Fedora/ # Fedora
            return true if contents =~ /^CentOS/ # CentOS
            return true if contents =~ /^Enterprise Linux Enterprise Linux/ # Oracle Linux < 5.3
            return true if contents =~ /^Red Hat Enterprise Linux/ # Red Hat Enterprise Linux and Oracle Linux >= 5.3
          end
        end

        false
      end

      # Normal, mid-range precedence.
      def self.precedence
        5
      end

      def initialize(*args)
        super

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
        @nfs_apply_command = "/usr/sbin/exportfs -r"
        @nfs_check_command = "#{nfs_server_binary} status"
        @nfs_start_command = "#{nfs_server_binary} start"
      end
    end
  end
end
