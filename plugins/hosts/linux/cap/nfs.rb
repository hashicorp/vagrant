require "vagrant/util"
require "vagrant/util/shell_quote"
require "vagrant/util/retryable"

module VagrantPlugins
  module HostLinux
    module Cap
      class NFS

        NFS_EXPORTS_PATH = "/etc/exports".freeze
        extend Vagrant::Util::Retryable

        def self.nfs_check_command(env)
          "/etc/init.d/nfs-kernel-server status"
        end

        def self.nfs_start_command(env)
          "/etc/init.d/nfs-kernel-server start"
        end

        def self.nfs_export(env, ui, id, ips, folders)
          # Get some values we need before we do anything
          nfs_check_command = env.host.capability(:nfs_check_command)
          nfs_start_command = env.host.capability(:nfs_start_command)

          nfs_opts_setup(folders)

          ui.info I18n.t("vagrant.hosts.linux.nfs_export")
          sleep 0.5

          nfs_cleanup("#{Process.uid} #{id}")
          output = "#{nfs_exports_content}\n#{output}"
          nfs_write_exports(output)

          if !nfs_running?(nfs_check_command)
            system("sudo #{nfs_start_command}")
          end

          ips.each do |ip|
            folders.each_value do |opts|
              system("sudo exportfs -o #{opts[:linux__nfs_options].join(',')} #{ip}:#{opts[:hostpath]}")
            end
          end
        end

        def self.nfs_installed(environment)
          retryable(tries: 10, on: TypeError) do
            # Check procfs to see if NFSd is a supported filesystem
            system("cat /proc/filesystems | grep nfsd > /dev/null 2>&1")
          end
        end

        def self.nfs_prune(environment, ui, valid_ids)
          logger = Log4r::Logger.new("vagrant::hosts::linux")
          logger.info("Pruning invalid NFS entries...")

          output = false

          nfs_current_exports.each do |export|
            if id = export[:linux__nfs_options][/replicas=([\w-]+)?/, 1]
              if valid_ids.include?(id)
                logger.debug("Valid ID: #{id}")
              else
                if !output
                  # We want to warn the user but we only want to output once
                  ui.info I18n.t("vagrant.hosts.linux.nfs_prune")
                  output = true
                end

                logger.info("Invalid ID, pruning: #{id}")
                nfs_cleanup(export[:ip], export[:hostpath])
              end
            end
          end
        end

        protected

        def self.nfs_cleanup(ip, host)
          system("sudo exportfs -u #{ip}:#{host}")
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
            opts[:linux__nfs_options] << "fsid=#{opts[:fsid]}"
            # We need to store reference to machine somewhere, `replicas`
            # seems to be the only place it is possible and harmless
            opts[:linux__nfs_options] << "replicas=#{opts[:uuid]}"
          end
        end

        def self.nfs_running?(check_command)
          system(check_command)
        end

        def self.nfs_current_exports
          exports = `sudo exportfs -v`

          # exportfs output should be properly parsed
          #
          # This is a little bit complicated because folder with long path looks like this:
          #   `sudo exportfs -v`
          #   #=> "/very_long_path\n\t\t192.168.122.4(rw,all_squash,no_subtree_check,fsid=180077614,replicas=8c085523-3e67-48b3-a362-613167dde240)"
          #
          # while short path looks like this:
          #   `sudo exportfs -v`
          #   #=> "/short_path      \t192.168.122.153(rw,all_squash,no_subtree_check,fsid=180077614,replicas=8c085523-3e67-48b3-a362-613167dde240)"
          #
          # We need to properly handle both cases.
          exports.gsub!(/\n\t/, ' ')
          exports_line_regexp = /
            \A
              (.+?)                 # full path to directory
              \s+                   # separator between path and IP address
              (\d+\.\d+\.\d+\.\d+)  # IP address
              \((.+)\)              # NFS options
            \z
          /x

          exports.split("\n").map do |line|
            path, ip_address, nfs_options = line.scan(exports_line_regexp).first
            {
              :hostpath => path,
              :ip => ip_address,
              :linux__nfs_options => nfs_options
            }
          end
        end

        def self.nfs_export_
      end
    end
  end
end
