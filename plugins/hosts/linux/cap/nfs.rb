require "vagrant/util"
require "vagrant/util/shell_quote"
require "vagrant/util/retryable"

module VagrantPlugins
  module HostLinux
    module Cap
      class NFS
        extend Vagrant::Util::Retryable

        def self.nfs_apply_command(env)
          "exportfs -ar"
        end

        def self.nfs_check_command(env)
          "/etc/init.d/nfs-kernel-server status"
        end

        def self.nfs_start_command(env)
          "/etc/init.d/nfs-kernel-server start"
        end

        def self.nfs_export(env, ui, id, ips, folders)
          # Get some values we need before we do anything
          nfs_apply_command = env.host.capability(:nfs_apply_command)
          nfs_check_command = env.host.capability(:nfs_check_command)
          nfs_start_command = env.host.capability(:nfs_start_command)

          nfs_opts_setup(folders)
          output = Vagrant::Util::TemplateRenderer.render('nfs/exports_linux',
                                           uuid: id,
                                           ips: ips,
                                           folders: folders,
                                           user: Process.uid)

          ui.info I18n.t("vagrant.hosts.linux.nfs_export")
          sleep 0.5

          nfs_cleanup(id)

          # Only use "sudo" if we can't write to /etc/exports directly
          sudo_command = ""
          sudo_command = "sudo " if !File.writable?("/etc/exports")

          output.split("\n").each do |line|
            line = Vagrant::Util::ShellQuote.escape(line, "'")
            system(%Q[echo '#{line}' | #{sudo_command}tee -a /etc/exports >/dev/null])
          end

          if nfs_running?(nfs_check_command)
            system("sudo #{nfs_apply_command}")
          else
            system("sudo #{nfs_start_command}")
          end
        end

        def self.nfs_installed(environment)
          retryable(tries: 10, on: TypeError) do
            # Check procfs to see if NFSd is a supported filesystem
            system("cat /proc/filesystems | grep nfsd > /dev/null 2>&1")
          end
        end

        def self.nfs_prune(environment, ui, valid_ids)
          return if !File.exist?("/etc/exports")

          logger = Log4r::Logger.new("vagrant::hosts::linux")
          logger.info("Pruning invalid NFS entries...")

          output = false
          user = Process.uid

          File.read("/etc/exports").lines.each do |line|
            if id = line[/^# VAGRANT-BEGIN:( #{user})? ([\.\/A-Za-z0-9\-_:]+?)$/, 2]
              if valid_ids.include?(id)
                logger.debug("Valid ID: #{id}")
              else
                if !output
                  # We want to warn the user but we only want to output once
                  ui.info I18n.t("vagrant.hosts.linux.nfs_prune")
                  output = true
                end

                logger.info("Invalid ID, pruning: #{id}")
                nfs_cleanup(id)
              end
            end
          end
        end

        protected

        def self.nfs_cleanup(id)
          return if !File.exist?("/etc/exports")

          user = Regexp.escape(Process.uid.to_s)
          id   = Regexp.escape(id.to_s)

          # Only use "sudo" if we can't write to /etc/exports directly
          sudo_command = ""
          sudo_command = "sudo " if !File.writable?("/etc/exports")

          # Use sed to just strip out the block of code which was inserted
          # by Vagrant
          tmp = ENV["TMPDIR"] || ENV["TMP"] || "/tmp"
          system("cp /etc/exports '#{tmp}' && #{sudo_command}sed -r -e '\\\x01^# VAGRANT-BEGIN:( #{user})? #{id}\x01,\\\x01^# VAGRANT-END:( #{user})? #{id}\x01 d' -ibak '#{tmp}/exports' ; #{sudo_command}cp '#{tmp}/exports' /etc/exports")
        end

        def self.nfs_opts_setup(folders)
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

        def self.nfs_running?(check_command)
          system(check_command)
        end
      end
    end
  end
end
