module Vagrant
  module Hosts
    # Represents a BSD host, such as FreeBSD and Darwin (Mac OS X).
    class BSD < Base
      include Util

      def nfs?
        system("which nfsd > /dev/null 2>&1")
        $?.to_i == 0
      rescue TypeError
        false
      end

      def nfs_export(ip, folders)
        output = TemplateRenderer.render('nfs/exports',
                                         :uuid => env.vm.uuid,
                                         :ip => ip,
                                         :folders => folders)

        env.logger.info "Preparing to edit /etc/exports. Administrator priveleges will be required..."
        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        system("sudo nfsd restart")
      end

      def nfs_cleanup
        system("cat /etc/exports | grep 'VAGRANT-BEGIN: #{env.vm.uuid}' > /dev/null 2>&1")

        if $?.to_i == 0
          # Use sed to just strip out the block of code which was inserted
          # by Vagrant
          system("sudo sed -e '/^# VAGRANT-BEGIN: #{env.vm.uuid}/,/^# VAGRANT-END: #{env.vm.uuid}/ d' -i bak /etc/exports")
        end
      end
    end
  end
end
