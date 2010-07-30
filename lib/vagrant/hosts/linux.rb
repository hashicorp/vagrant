module Vagrant
  module Hosts
    # Represents a Linux based host, such as Ubuntu.
    class Linux < Base
      include Util

      def nfs?
        tries = 10
        begin
          # Check procfs to see if NFSd is a supported filesystem
          system("cat /proc/filesystems | grep nfsd > /dev/null 2>&1")
        rescue TypeError
          tries -= 1
          retry if tries > 0

          # Hopefully this point isn't reached
          raise
        end
      end

      def nfs_export(ip, folders)
        output = TemplateRenderer.render('nfs/exports_linux',
                                         :uuid => env.vm.uuid,
                                         :ip => ip,
                                         :folders => folders)

        env.logger.info "Preparing to edit /etc/exports. Administrator priveleges will be required..."
        sleep 0.5

        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        system("sudo /etc/init.d/nfs-kernel-server restart")
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
