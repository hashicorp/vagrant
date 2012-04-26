module VagrantPlugins
  module HostArch
    class Host < VagrantPlugins::HostLinux::Host
      def self.match?
        File.exist?("/etc/rc.conf") && File.exist?("/etc/pacman.conf")
      end

      # Normal, mid-range precedence.
      def self.precedence
        5
      end

      def nfs_export(id, ip, folders)
        output = TemplateRenderer.render('nfs/exports_linux',
                                         :uuid => id,
                                         :ip => ip,
                                         :folders => folders)

        @ui.info I18n.t("vagrant.hosts.arch.nfs_export.prepare")
        sleep 0.5

        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        system("sudo /etc/rc.d/rpcbind restart")
        system("sudo /etc/rc.d/nfs-common restart")
        system("sudo /etc/rc.d/nfs-server restart")
      end
    end
  end
end
