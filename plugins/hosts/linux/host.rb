require 'log4r'

require "vagrant"
require 'vagrant/util/platform'

module VagrantPlugins
  module HostLinux
    # Represents a Linux based host, such as Ubuntu.
    class Host < Vagrant.plugin("2", :host)
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
        @nfs_apply_command = "/usr/sbin/exportfs -r"
        @nfs_check_command = "/etc/init.d/nfs-kernel-server status"
        @nfs_start_command = "/etc/init.d/nfs-kernel-server start"
      end

      def nfs?
        retryable(:tries => 10, :on => TypeError) do
          # Check procfs to see if NFSd is a supported filesystem
          system("cat /proc/filesystems | grep nfsd > /dev/null 2>&1")
        end
      end

      def nfs_opts_setup(folders)
        folders.each do |k, opts|
          if !opts[:linux__nfs_options]
            opts[:linux__nfs_options] ||= ["rw", "no_subtree_check", "all_squash"]
          end

          # Only automatically set anonuid/anongid if they weren't
          # explicitly set by the user.
          hasgid = false
          hasuid = false
          opts[:linux__nfs_options].each do |opt|
            hasgid = !!(opt =~ /^anongid=/) if !hasgid
            hasuid = !!(opt =~ /^anonuid=/) if !hasuid
          end

          opts[:linux__nfs_options] << "anonuid=#{opts[:map_uid]}" if !hasuid
          opts[:linux__nfs_options] << "anongid=#{opts[:map_gid]}" if !hasgid
          opts[:linux__nfs_options] << "fsid=#{opts[:uuid]}"
        end
      end

      def nfs_export(id, ips, folders)
        nfs_opts_setup(folders)
        output = TemplateRenderer.render('nfs/exports_linux',
                                         :uuid => id,
                                         :ips => ips,
                                         :folders => folders,
                                         :user => Process.uid)

        @ui.info I18n.t("vagrant.hosts.linux.nfs_export")
        sleep 0.5

        nfs_cleanup(id)

        output.split("\n").each do |line|
          # This should only ask for administrative permission once, even
          # though its executed in multiple subshells.
          system(%Q[sudo su root -c "echo '#{line}' >> /etc/exports"])
        end

        if nfs_running?
          system("sudo #{@nfs_apply_command}")
        else
          system("sudo #{@nfs_start_command}")
        end
      end

      def nfs_prune(valid_ids)
        return if !File.exist?("/etc/exports")

        @logger.info("Pruning invalid NFS entries...")

        output = false
        user = Process.uid

        File.read("/etc/exports").lines.each do |line|
          if id = line[/^# VAGRANT-BEGIN:( #{user})? ([A-Za-z0-9-]+?)$/, 2]
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

      def nfs_running?
        system("#{@nfs_check_command}")
      end

      def nfs_cleanup(id)
        return if !File.exist?("/etc/exports")

        user = Process.uid
        # Use sed to just strip out the block of code which was inserted
        # by Vagrant
        system("sudo sed -r -e '/^# VAGRANT-BEGIN:( #{user})? #{id}/,/^# VAGRANT-END:( #{user})? #{id}/ d' -ibak /etc/exports")
      end
    end
  end
end
