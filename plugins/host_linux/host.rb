require 'log4r'

require 'vagrant/util/platform'

module VagrantPlugins
  module HostLinux
    # Represents a Linux based host, such as Ubuntu.
    class Host < Vagrant::Hosts::Base
      include Vagrant::Util
      include Vagrant::Util::Retryable

      def self.match?
        Vagrant::Util::Platform.linux?
      end

      def self.precedence
        # Set a lower precedence because this is a generic OS. We
        # want specific distros to match first.
        2
      end

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::hosts::linux")
        @nfs_server_binary = "/etc/init.d/nfs-kernel-server"
      end

      def nfs?
        retryable(:tries => 10, :on => TypeError) do
          # Check procfs to see if NFSd is a supported filesystem
          system("cat /proc/filesystems | grep nfsd > /dev/null 2>&1")
        end
      end

      def nfs_export(id, ip, folders)
        output = TemplateRenderer.render('nfs/exports_linux',
                                         :uuid => id,
                                         :ip => ip,
                                         :folders => folders)

        @ui.info I18n.t("vagrant.hosts.linux.nfs_export")
        sleep 0.5

        nfs_cleanup(id)

        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        # We run restart here instead of "update" just in case nfsd
        # is not starting
        system("sudo #{@nfs_server_binary} restart")
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
                @ui.info I18n.t("vagrant.hosts.linux.nfs_prune")
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
        # by Vagrant
        system("sudo sed -e '/^# VAGRANT-BEGIN: #{id}/,/^# VAGRANT-END: #{id}/ d' -ibak /etc/exports")
      end
    end
  end
end
