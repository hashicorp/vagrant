require 'vagrant/util/platform'

module Vagrant
  module Hosts
    # Represents a BSD host, such as FreeBSD and Darwin (Mac OS X).
    class BSD < Base
      include Util
      include Util::Retryable

      def self.distro_dispatch
        return self if Util::Platform.darwin? || Util::Platform.bsd?
      end

      def nfs?
        retryable(:tries => 10, :on => TypeError) do
          system("which nfsd > /dev/null 2>&1")
        end
      end

      def nfs_export(ip, folders)
        output = TemplateRenderer.render('nfs/exports',
                                         :uuid => env.vm.uuid,
                                         :ip => ip,
                                         :folders => folders)

        # The sleep ensures that the output is truly flushed before any `sudo`
        # commands are issued.
        env.ui.info I18n.t("vagrant.hosts.bsd.nfs_export.prepare")
        sleep 0.5

        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          line = line.gsub('"', '\"')
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        system("sudo nfsd restart")
      end

      def nfs_cleanup
        return if !File.exist?("/etc/exports")

        retryable(:tries => 10, :on => TypeError) do
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
end
