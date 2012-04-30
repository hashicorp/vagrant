require 'log4r'

require 'vagrant/util/platform'

module VagrantPlugins
  module HostBSD
    # Represents a BSD host, such as FreeBSD and Darwin (Mac OS X).
    class Host < Vagrant::Hosts::Base
      include Vagrant::Util
      include Vagrant::Util::Retryable

      def self.match?
        Vagrant::Util::Platform.darwin? || Vagrant::Util::Platform.bsd?
      end

      def self.precedence
        # Set a lower precedence because this is a generic OS. We
        # want specific distros to match first.
        2
      end

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::hosts::bsd")
        @nfs_restart_command = "sudo nfsd restart"
        @nfs_exports_template = "nfs/exports"
      end

      def nfs?
        retryable(:tries => 10, :on => TypeError) do
          system("which nfsd > /dev/null 2>&1")
        end
      end

      def nfs_export(id, ip, folders)
        output = TemplateRenderer.render(@nfs_exports_template,
                                         :uuid => id,
                                         :ip => ip,
                                         :folders => folders)

        # The sleep ensures that the output is truly flushed before any `sudo`
        # commands are issued.
        @ui.info I18n.t("vagrant.hosts.bsd.nfs_export")
        sleep 0.5

        # First, clean up the old entry
        nfs_cleanup(id)

        # Output the rendered template into the exports
        output.split("\n").each do |line|
          line = line.gsub('"', '\"')
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        system(@nfs_restart_command)
      end

      def nfs_prune(valid_ids)
        return if !File.exist?("/etc/exports")

        @logger.info("Pruning invalid NFS entries...")

        output = false

        File.read("/etc/exports").lines.each do |line|
          if id = line[/^# VAGRANT-BEGIN: (.+?)$/, 1]
            if valid_ids.include?(id)
              @logger.debug("Valid ID: #{id}")
            else
              if !output
                # We want to warn the user but we only want to output once
                @ui.info I18n.t("vagrant.hosts.bsd.nfs_prune")
                output = true
              end

              @logger.info("Invalid ID, pruning: #{id}")
              nfs_cleanup(id)
            end
          end
        end
      end

      protected

      def nfs_cleanup(id)
        return if !File.exist?("/etc/exports")

        # Use sed to just strip out the block of code which was inserted
        # by Vagrant, and restart NFS.
        system("sudo sed -e '/^# VAGRANT-BEGIN: #{id}/,/^# VAGRANT-END: #{id}/ d' -ibak /etc/exports")
      end
    end
  end
end
