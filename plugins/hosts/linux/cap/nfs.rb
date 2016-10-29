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
          nfs_write_exports(output)

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

          user = Process.uid

          # Create editor instance for removing invalid IDs
          editor = Util::StringBlockEditor.new(File.read("/etc/exports"))

          # Build composite IDs with UID information and discover invalid entries
          composite_ids = valid_ids.map do |v_id|
            "#{user} #{v_id}"
          end
          remove_ids = editor.keys - composite_keys

          logger.debug("Known valid NFS export IDs: #{valid_ids}")
          logger.debug("Composite valid NFS export IDs with user: #{composite_ids}")
          logger.debug("NFS export IDs to be removed: #{remove_ids}")
          if !remove_ids.empty?
            ui.info I18n.t("vagrant.hosts.linux.nfs_prune")
            nfs_cleanup(remove_ids)
          end
        end

        protected

        def self.nfs_cleanup(remove_ids)
          return if !File.exist?("/etc/exports")

          editor = Util::StringBlockEditor.new(File.read("/etc/exports"))
          remove_ids = Array(remove_ids)

          # Remove all invalid ID entries
          remove_ids.each do |r_id|
            editor.delete(r_id)
          end
          nfs_write_exports(editor.value)
        end

        def self.nfs_write_exports(new_exports_content)
          # Write contents out to temporary file
          new_exports_file = Tempfile.create('vagrant')
          new_exports_file.puts(new_exports_content)
          new_exports_file.close
          new_exports_path = new_exports_file.path

          if !FileUtils.compare_file(new_exports_path, "/etc/exports")
            # Only use "sudo" if we can't write to /etc/exports directly
            sudo_command = ""
            sudo_command = "sudo " if !File.writable?("/etc/exports")

            # Ensure new file mode and uid/gid match existing file to replace
            existing_stat = File.stat("/etc/exports")
            new_stat = File.stat(new_exports_path)
            if existing_stat.mode != new_stat.mode
              File.chmod(existing_stat.mode, new_exports_path)
            end
            # TODO: Error check
            if existing_stat.uid != new_stat.uid || existing_stat.gid != new_stat.gid
              system("#{sudo_command}chown #{existing_stat.uid}:#{existing_stat.gid} #{new_exports_path}")
            end

            # Replace existing exports file
            system("#{sudo_command}mv #{new_exports_path} /etc/exports")
          end
        ensure
          if File.exist?(new_exports_path)
            File.unlink(new_exports_path)
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
          system(check_command)
        end
      end
    end
  end
end
