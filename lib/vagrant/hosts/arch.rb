module Vagrant
  module Hosts
    class Arch < Linux
      def self.match?
        File.exist?("/etc/os-release") && File.read("/etc/os-release") =~ /arch linux/i
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

        nfs_cleanup(id)

        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case the
        # services are not yet started
        if systemd?
          system("sudo systemctl restart nfsd.service rpc-idmapd.service rpc-mountd.service rpcbind.service")
        else
          system("sudo /etc/rc.d/rpcbind restart")
          system("sudo /etc/rc.d/nfs-common restart")
          system("sudo /etc/rc.d/nfs-server restart")
        end
      end

      private

      def systemd?
        system("which systemctl &>/dev/null")
      end
    end
  end
end
