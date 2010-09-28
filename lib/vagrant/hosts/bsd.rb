module Vagrant
  module Hosts
    # Represents a BSD host, such as FreeBSD and Darwin (Mac OS X).
    class BSD < Base
      include Util
      include Util::Retryable
      include Util::Sh

      def nfs?
        retryable(:tries => 10, :on => TypeError) do
          _, status = sh("which nfsd")

          # Sometimes the status is nil for some reason. In that case, force a retry
          raise TypeError.new("Bad status code") if !status
          status.success?
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
          sh(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        sh("sudo nfsd restart")
      end

      def nfs_cleanup
        return if !File.exist?("/etc/exports")
        _, status = sh("cat /etc/exports | grep 'VAGRANT-BEGIN: #{env.vm.uuid}'")

        if status.success?
          # Use sed to just strip out the block of code which was inserted
          # by Vagrant
          sh("sudo sed -e '/^# VAGRANT-BEGIN: #{env.vm.uuid}/,/^# VAGRANT-END: #{env.vm.uuid}/ d' -i bak /etc/exports")
        end
      end
    end
  end
end
