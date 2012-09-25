require "vagrant"

require Vagrant.source_root.join("plugins/hosts/linux/host")

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

        # This should only ask for administrative permission only once
        # You can use configure /etc/sudoers.d to avoid having to enter the password

        nfs_cleanup(id)

        # now we need to escape some chars to make sure sed will work
        # we know we make use of double-quotes, parenthesis, and multiple lines. So we are going to handle those cases
        output = output.gsub("\"", "\\\"")
        output = output.gsub("(", "\\(")
        output = output.gsub(")", "\\)")
        output = output.gsub("\n", "\\\n")
        sed_command = "sudo sed -e '$a#{output}' -ibak /etc/exports"
        system(sed_command)

        if systemd?
          # Call start to be nice. This will be a no-op if things are
          # already running. Then use exportfs to pick up the changes we
          # just made.
          system("sudo systemctl start nfsd.service rpc-idmapd.service rpc-mountd.service rpcbind.service")
          system("sudo exportfs -r")
        else
          # The restarting of services when we might not need to can be
          # considered evil, but this will be obviated by systemd soon
          # enough anyway.
          system("sudo /etc/rc.d/rpcbind restart")
          system("sudo /etc/rc.d/nfs-common restart")
          system("sudo /etc/rc.d/nfs-server restart")
        end
      end

      protected

      # This tests to see if systemd is used on the system. This is used
      # in newer versions of Arch, and requires a change in behavior.
      def systemd?
        Kernel.system("which systemctl &>/dev/null")
      end
    end
  end
end
