require "shellwords"
require "vagrant/util"
require "vagrant/util/shell_quote"
require "vagrant/util/retryable"

module VagrantPlugins
  module HostLinux
    module Cap
      class NFS

        DEFAULT_MOUNT_OPTIONS = ["rw", "no_subtree_check", "all_squash"].map(&:freeze).freeze

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

          if !nfs_running?(nfs_check_command)
            result = Vagrant::Util::Subprocess.execute(
              *Shellwords.split("sudo #{nfs_start_command}")
            )
            if result.exit_code != 0
              raise Vagrant::Errors::NFSDStartFailure,
                stderr: result.stderr,
                command: nfs_start_command
            end
          end

          export_info = ips.map do |ip|
            mounted_paths = []
            folders.each_value do |opts|
              exportfs_command = "exportfs -o #{opts[:linux__nfs_options].join(',')} " \
                "#{ip}:#{opts[:hostpath]}"
              result = Vagrant::Util::Subprocess.execute(
                *Shellwords.split("sudo #{exportfs_command}")
              )
              if result.exit_code != 0
                raise Vagrant::Errors::NFSExportfsExportFailed,
                  stderr: result.stderr,
                  command: exportfs_command
              end
              mounted_paths << opts[:hostpath]
            end
            {address: ip, paths: mounted_paths}
          end
          record_nfs_idmap(env, id, export_info)
        end

        def self.nfs_installed(environment)
          # Check procfs to see if NFSd is a supported filesystem
          File.read("/proc/filesystems").include?("nfsd")
        end

        def self.nfs_prune(environment, ui, valid_ids)
          logger = Log4r::Logger.new("vagrant::hosts::linux")
          logger.info("Pruning invalid NFS entries...")

          all_ids = load_nfs_idmap(environment)
          current_ids = all_ids.fetch(environment.default_provider.to_s, {})
          ids_to_prune = current_ids.keys - valid_ids

          if !ids_to_prune.empty?
            logger.debug("NFS ID entries to prune: #{ids_to_prune}")

            path_in_use = {}
            current_ids.each do |entry_id, entries|
              next if ids_to_prune.include?(entry_id)
              entries.each do |entry|
                entry.fetch("paths", {}).each do |path|
                  path_key = "#{entry["address"]}:#{path}"
                  path_in_use[path_key] ||= []
                  path_in_use[path_key] << entry_id
                end
              end
            end

            prune_entries = ids_to_prune.map do |entry_id|
              entries = current_ids[entry_id]
              entries.map do |entry|
                prune_paths = entry.fetch("paths", []).find_all do |host_path|
                  path_key = "#{entry["address"]}:#{host_path}"
                  path_in_use[path_key].nil? || path_in_use[path_key].empty?
                end
                {:id => entry_id, :paths => prune_paths, :ip => entry["address"]}
              end
            end.flatten(1)

            output = false
            nfs_current_exports.each do |export|

              prune_match = prune_entries.detect do |entry|
                entry[:ip] == export[:ip] && entry.fetch(:paths, []).include?(export[:hostpath])
              end

              if prune_match
                if !output
                  # We want to warn the user but we only want to output once
                  ui.info I18n.t("vagrant.hosts.linux.nfs_prune")
                  output = true
                end

                logger.info("Invalid ID, pruning: #{export[:ip]}:#{export[:hostpath]} (ID: #{prune_match[:id]})")
                nfs_cleanup(export[:ip], export[:hostpath])
              end
            end
            clean_nfs_idmap(environment, ids_to_prune)
          end
        end

        protected

        def self.nfs_cleanup(ip, host)
          prune_command = "exportfs -u #{ip}:#{host}"
          result = Vagrant::Util::Subprocess.execute(
            *Shellwords.split("sudo #{prune_command}")
          )
          if result.exit_code != 0
            raise Vagrant::Errors::NFSExportfsPruneFailed,
              stderr: result.stderr,
              command: prune_command
          end
        end

        def self.nfs_opts_setup(folders)
          folders.each do |k, opts|
            if !opts[:linux__nfs_options]
              opts[:linux__nfs_options] ||= DEFAULT_MOUNT_OPTIONS.dup
            end

            # Only automatically set anonuid/anongid/fsid if they weren't
            # explicitly set by the user.
            set_opts = opts[:linux__nfs_options].map do |opt|
              if opt.include?("anongid=")
                :map_gid
              elsif opt.include?("anonuid=")
                :map_uid
              elsif opt.include?("fsid=")
                :uuid
              end
            end.compact
            { map_gid: "anongid=#{opts[:map_gid]}",
                map_uid: "anonuid=#{opts[:map_uid]}",
                uuid: "fsid=#{opts[:uuid]}" }.each do |key, opt_string|
              if !set_opts.include?(key) && opts[key]
                opts[:linux__nfs_options] << opt_string
              end
            end
          end
        end

        def self.nfs_running?(check_command)
          result = Vagrant::Util::Subprocess.execute(*Shellwords.split(check_command))
          result.exit_code == 0
        end

        def self.nfs_current_exports
          exports = ""
          list_command = "exportfs -v"
          result = Vagrant::Util::Subprocess.execute(
            *Shellwords.split("sudo #{list_command}")
          )
          if result.exit_code != 0
            raise Vagrant::Errors::NFSExportfsListFailed,
              stderr: result.stderr,
              command: list_command
          end
          exports = result.stdout

          # exportfs output should be properly parsed
          #
          # This is a little bit complicated because folder with long path looks like this:
          #   `sudo exportfs -v`
          #   #=> "/very_long_path\n\t\t192.168.122.4(rw,all_squash,no_subtree_check,fsid=180077614)
          #
          # while short path looks like this:
          #   `sudo exportfs -v`
          #   #=> "/short_path      \t192.168.122.153(rw,all_squash,no_subtree_check,fsid=180077614)
          #
          # We need to properly handle both cases.
          exports.gsub!(/\n\t/, ' ')
          exports_line_regexp = /
            \A
              (?<hostpath>.+?)                 # full path to directory
              \s+                   # separator between path and IP address
              (?<ip_address>\d+\.\d+\.\d+\.\d+)  # IP address
              \((?<nfs_options>.+)\)              # NFS options
            \z
          /x

          exports.split("\n").map do |line|
            result = line.match(exports_line_regexp)
            next if result.nil?
            {
              :hostpath => result[:hostpath],
              :ip => result[:ip_address],
              :linux__nfs_options => result[:nfs_options]
            }
          end.compact
        end

        def self.nfs_idmap_path(environment)
          FileUtils.mkdir_p(environment.data_dir.join("synced_folders"))
          environment.data_dir.join("synced_folders/nfs-map.json")
        end

        def self.record_nfs_idmap(environment, id, mount_info)
          id_path = nfs_idmap_path(environment)
          environment.lock("nfs-idmap") do
            current_ids = load_nfs_idmap(environment)
            current_ids[environment.default_provider.to_s] ||= {}
            current_ids[environment.default_provider.to_s][id.to_s] = mount_info
            File.write(id_path, JSON.dump(current_ids))
          end
        end

        def self.clean_nfs_idmap(environment, remove_ids)
          id_path = nfs_idmap_path(environment)
          environment.lock("nfs-idmap") do
            current_ids = load_nfs_idmap(environment)
            if current_ids[environment.default_provider.to_s]
              remove_ids.each do |entry_id|
                current_ids[environment.default_provider.to_s].delete(entry_id.to_s)
              end
            end
            File.write(id_path, JSON.dump(current_ids))
          end
        end

        def self.load_nfs_idmap(environment)
          id_path = nfs_idmap_path(environment)
          if File.exist?(id_path)
            environment.lock("nfs-idmap") do
              JSON.parse(File.read(id_path))
            end
          else
            {}
          end
        end
      end
    end
  end
end
