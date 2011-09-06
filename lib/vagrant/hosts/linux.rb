require 'vagrant/util/platform'

module Vagrant
  module Hosts
    # Represents a Linux based host, such as Ubuntu.
    class Linux < Base
      include Util
      include Util::Retryable

      def self.distro_dispatch
        return nil if !Util::Platform.linux?
        return Arch if File.exist?("/etc/rc.conf") && File.exist?("/etc/pacman.conf")

        if File.exist?("/etc/redhat-release")
          # Check if we have a known redhat release
          File.open("/etc/redhat-release") do |f|
            return Fedora if f.gets =~ /^Fedora/
          end
        end

        return self
      end

      def initialize(*args)
        super

        @nfs_server_binary = "/etc/init.d/nfs-kernel-server"
      end

      def nfs?
        retryable(:tries => 10, :on => TypeError) do
          # Check procfs to see if NFSd is a supported filesystem
          system("cat /proc/filesystems | grep nfsd > /dev/null 2>&1")
        end
      end

      def nfs_export(ip, folders)
        output = TemplateRenderer.render('nfs/exports_linux',
                                         :uuid => env.vm.uuid,
                                         :ip => ip,
                                         :folders => folders)

        env.ui.info I18n.t("vagrant.hosts.linux.nfs_export.prepare")
        sleep 0.5

        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        system("sudo #{@nfs_server_binary} restart")
      end

      def nfs_cleanup
        return if !File.exist?("/etc/exports")
        system("cat /etc/exports | grep 'VAGRANT-BEGIN: #{env.vm.uuid}' > /dev/null 2>&1")

        if $?.to_i == 0
          # Use sed to just strip out the block of code which was inserted
          # by Vagrant
          system("sudo sed -e '/^# VAGRANT-BEGIN: #{env.vm.uuid}/,/^# VAGRANT-END: #{env.vm.uuid}/ d' -ibak /etc/exports")
        end
      end
    end
  end
end
