require "shellwords"
require "vagrant/util"
require "vagrant/util/shell_quote"
require "vagrant/util/retryable"

module VagrantPlugins
  module HostLinux
    module Cap
      class NFS

        NFS_EXPORTS_PATH = "/etc/exports".freeze
        extend Vagrant::Util::Retryable

        def self.nfs_apply_command(env)
          "exportfs -ar"
        end

        def self.nfs_check_command(env)
          if Vagrant::Util::Platform.systemd?
            "systemctl status --no-pager nfs-server.service"
          else
            "/etc/init.d/nfs-kernel-server status"
          end
        end

        def self.nfs_start_command(env)
          if Vagrant::Util::Platform.systemd?
            "systemctl start nfs-server.service"
          else
            "/etc/init.d/nfs-kernel-server start"
          end
        end

        def self.nfs_export(env, ui, id, ips, folders)
          # Get some values we need before we do anything
          nfs_apply_command = env.host.capability(:nfs_apply_command)
          nfs_check_command = env.host.capability(:nfs_check_command)
          nfs_start_command = env.host.capability(:nfs_start_command)

          nfs_opts_setup(folders)
          folders = folder_dupe_check(folders)
          output = Vagrant::Util::TemplateRenderer.render('nfs/exports_linux',
                                           uuid: id,
                                           ips: ips,
                                           folders: folders,
                                           user: Process.uid)

          ui.info I18n.t("vagrant.hosts.linux.nfs_export")
          sleep 0.5

          nfs_cleanup("#{Process.uid} #{id}")
          output = "#{nfs_exports_content}\n#{output}"
          nfs_write_exports(output)

          if nfs_running?(nfs_check_command)
            Vagrant::Util::Subprocess.execute("sudo", *Shellwords.split(nfs_apply_command)).exit_code == 0
          else
            Vagrant::Util::Subprocess.execute("sudo", *Shellwords.split(nfs_start_command)).exit_code == 0
          end
        end

        def self.nfs_installed(environment)
          if Vagrant::Util::Platform.systemd?
            Vagrant::Util::Subprocess.execute("/bin/sh", "-c",
              "systemctl --no-pager --no-legend --plain list-unit-files --all --type=service " \
                "| grep nfs-server.service").exit_code == 0
          else
            Vagrant::Util::Subprocess.execute("modinfo", "nfsd").exit_code == 0 ||
              Vagrant::Util::Subprocess.execute("grep", "nfsd", "/proc/filesystems").exit_code == 0
          end
        end

        def self.nfs_prune(environment, ui, valid_ids)
          return if !File.exist?(NFS_EXPORTS_PATH)

          logger = Log4r::Logger.new("vagrant::hosts::linux")
          logger.info("Pruning invalid NFS entries...")

          user = Process.uid

          # Create editor instance for removing invalid IDs
          editor = Vagrant::Util::StringBlockEditor.new(nfs_exports_content)

          # Build composite IDs with UID information and discover invalid entries
          composite_ids = valid_ids.map do |v_id|
            "#{user} #{v_id}"
          end
          remove_ids = editor.keys - composite_ids

          logger.debug("Known valid NFS export IDs: #{valid_ids}")
          logger.debug("Composite valid NFS export IDs with user: #{composite_ids}")
          logger.debug("NFS export IDs to be removed: #{remove_ids}")
          if !remove_ids.empty?
            ui.info I18n.t("vagrant.hosts.linux.nfs_prune")
            nfs_cleanup(remove_ids)
          end
        end

        protected

        # Takes a hash of folders and removes any duplicate exports that
        # share the same hostpath to avoid duplicate entries in /etc/exports
        # ref: GH-4666
        def self.folder_dupe_check(folders)
          return_folders = {}
          # Group by hostpath to see if there are multiple exports coming
          # from the same folder
          export_groups = folders.values.group_by { |h| h[:hostpath] }

          # We need to check that each group key only has 1 value,
          # and if not, check each nfs option. If all nfs options are the same
          # we're good, otherwise throw an exception
          export_groups.each do |path,group|
            if group.size > 1
              # if the linux nfs options aren't all the same throw an exception
              group1_opts = group.first[:linux__nfs_options]

              if !group.all? {|g| g[:linux__nfs_options] == group1_opts}
                raise Vagrant::Errors::NFSDupePerms, hostpath: group.first[:hostpath]
              else
                # if they're the same just pick the first one
                return_folders[path] = group.first
              end
            else
              # just return folder, there are no duplicates
              return_folders[path] = group.first
            end
          end
          return_folders
        end

        def self.nfs_cleanup(remove_ids)
          return if !File.exist?(NFS_EXPORTS_PATH)

          editor = Vagrant::Util::StringBlockEditor.new(nfs_exports_content)
          remove_ids = Array(remove_ids)

          # Remove all invalid ID entries
          remove_ids.each do |r_id|
            editor.delete(r_id)
          end
          nfs_write_exports(editor.value)
        end

        def self.nfs_write_exports(new_exports_content)
          if(nfs_exports_content != new_exports_content.strip)
            begin
              # Write contents out to temporary file
              new_exports_file = Tempfile.create('vagrant')
              new_exports_file.puts(new_exports_content)
              new_exports_file.close
              new_exports_path = new_exports_file.path

              # Only use "sudo" if we can't write to /etc/exports directly
              sudo_command = ""
              sudo_command = "sudo " if !File.writable?(NFS_EXPORTS_PATH)

              # Ensure new file mode and uid/gid match existing file to replace
              existing_stat = File.stat(NFS_EXPORTS_PATH)
              new_stat = File.stat(new_exports_path)
              if existing_stat.mode != new_stat.mode
                File.chmod(existing_stat.mode, new_exports_path)
              end
              if existing_stat.uid != new_stat.uid || existing_stat.gid != new_stat.gid
                chown_cmd = "#{sudo_command}chown #{existing_stat.uid}:#{existing_stat.gid} #{new_exports_path}"
                result = Vagrant::Util::Subprocess.execute(*Shellwords.split(chown_cmd))
                if result.exit_code != 0
                  raise Vagrant::Errors::NFSExportsFailed,
                    command: chown_cmd,
                    stderr: result.stderr,
                    stdout: result.stdout
                end
              end
              # Always force move the file to prevent overwrite prompting
              mv_cmd = "#{sudo_command}mv -f #{new_exports_path} #{NFS_EXPORTS_PATH}"
              result = Vagrant::Util::Subprocess.execute(*Shellwords.split(mv_cmd))
              if result.exit_code != 0
                raise Vagrant::Errors::NFSExportsFailed,
                  command: mv_cmd,
                  stderr: result.stderr,
                  stdout: result.stdout
              end
            ensure
              if File.exist?(new_exports_path)
                File.unlink(new_exports_path)
              end
            end
          end
        end

        def self.nfs_exports_content
          if(File.exist?(NFS_EXPORTS_PATH))
            if(File.readable?(NFS_EXPORTS_PATH))
              File.read(NFS_EXPORTS_PATH)
            else
              cmd = "sudo cat #{NFS_EXPORTS_PATH}"
              result = Vagrant::Util::Subprocess.execute(*Shellwords.split(cmd))
              if result.exit_code != 0
                raise Vagrant::Errors::NFSExportsFailed,
                  command: cmd,
                  stderr: result.stderr,
                  stdout: result.stdout
              else
                result.stdout
              end
            end
          else
            ""
          end
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
          Vagrant::Util::Subprocess.execute(*Shellwords.split(check_command)).exit_code == 0
        end
      end
    end
  end
end
