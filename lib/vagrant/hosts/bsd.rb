require 'vagrant/util/platform'

module Vagrant
  module Hosts
    # Represents a BSD host, such as FreeBSD and Darwin (Mac OS X).
    class BSD < Base
      include Util
      include Util::Retryable

      def self.match?
        Util::Platform.darwin? || Util::Platform.bsd?
      end

      def self.precedence
        # Set a lower precedence because this is a generic OS. We
        # want specific distros to match first.
        2
      end

      def initialize(*args)
        super

        @nfs_restart_command = "sudo nfsd restart"
      end

      def nfs?
        retryable(:tries => 10, :on => TypeError) do
          system("which nfsd > /dev/null 2>&1")
        end
      end

      def nfs_export(id, ip, folders)
        output = TemplateRenderer.render('nfs/exports',
                                         :uuid => id,
                                         :ip => ip,
                                         :folders => folders)

        # The sleep ensures that the output is truly flushed before any `sudo`
        # commands are issued.
        @ui.info I18n.t("vagrant.hosts.bsd.nfs_export.prepare")
        sleep 0.5

        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          line = line.gsub('"', '\"')
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        system(@nfs_restart_command)
      end

      def nfs_cleanup(id)
        return if !File.exist?("/etc/exports")

        retryable(:tries => 10, :on => TypeError) do
          system("cat /etc/exports | grep 'VAGRANT-BEGIN: #{id}' > /dev/null 2>&1")

          if $?.to_i == 0
            # Use sed to just strip out the block of code which was inserted
            # by Vagrant, and restart NFS.
            system("sudo sed -e '/^# VAGRANT-BEGIN: #{id}/,/^# VAGRANT-END: #{id}/ d' -ibak /etc/exports")
            system(@nfs_restart_command)
          end
        end
      end
    end
  end
end
