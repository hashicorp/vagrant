require "log4r"

require "vagrant/util"
require "vagrant/util/shell_quote"
require "vagrant/util/which"

module VagrantPlugins
  module HostBSD
    module Cap
      class NFS
        # On OS X 10.15, / is read-only and paths inside of /Users (and elsewhere) are mounted
        # via a "firmlink" (which is a new invention in APFS). These must be resolved to their
        # full path to be shareable via NFS.
        # /Users/johnsmith/mycode   becomes   /System/Volumes/Data/Users/johnsmith/mycode
        # we check to see if a path is mounted here with `df`, and prepend it.
        #
        # Firmlinks are only createable by the OS, so a hardcoded path should be fine, until
        # Apple gets crazier. This wasn't supposed to be visible to applications anyway:
        # https://developer.apple.com/videos/play/wwdc2019/710/?time=481
        # see also https://github.com/hashicorp/vagrant/issues/10961
        OSX_FIRMLINK_HACK = "/System/Volumes/Data"

        def self.nfs_export(environment, ui, id, ips, folders)
          nfs_exports_template = environment.host.capability(:nfs_exports_template)
          nfs_restart_command  = environment.host.capability(:nfs_restart_command)
          logger = Log4r::Logger.new("vagrant::hosts::bsd")

          nfs_checkexports! if File.file?("/etc/exports")

          # Check to see if this folder is mounted 1) as APFS and 2) within the /System/Volumes/Data volume
          # on OS X, which is a read-write "firmlink", and must be prepended so it can be shared via NFS
          # we also need to directly mutate the :hostpath if we change it, so that it's mounted with the
          # prefix.
          logger.debug("Checking to see if NFS exports are in an APFS firmlink...")
          nfs_check_folders_for_apfs folders

          # We need to build up mapping of directories that are enclosed
          # within each other because the exports file has to have subdirectories
          # of an exported directory on the same line. e.g.:
          #
          #   "/foo" "/foo/bar" ...
          #   "/bar"
          #
          # We build up this mapping within the following hash.
          logger.debug("Compiling map of sub-directories for NFS exports...")
          dirmap = {}
          folders.sort_by { |_, opts| opts[:hostpath] }.each do |_, opts|
            hostpath = opts[:hostpath].dup
            hostpath.gsub!('"', '\"')

            found = false
            dirmap.each do |dirs, diropts|
              dirs.each do |dir|
                if dir.start_with?(hostpath) || hostpath.start_with?(dir)
                  # TODO: verify opts and diropts are _identical_, raise an error
                  # if not. NFS mandates subdirectories have identical options.
                  dirs << hostpath
                  found = true
                  break
                end
              end

              break if found
            end

            if !found
              dirmap[[hostpath]] = opts.dup
            end
          end

          # Sort all the keys by length so that the directory closest to
          # the root is exported first. Also, remove duplicates so that
          # checkexports will work properly.
          dirmap.each do |dirs, _|
            dirs.uniq!
            dirs.sort_by! { |d| d.length }
          end

          # Setup the NFS options
          dirmap.each do |dirs, opts|
            if !opts[:bsd__nfs_options]
              opts[:bsd__nfs_options] = ["alldirs"]
            end

            hasmapall = false
            opts[:bsd__nfs_options].each do |opt|
              # mapall/maproot are mutually exclusive, so we have to check
              # for both here.
              if opt =~ /^mapall=/ || opt =~ /^maproot=/
                hasmapall = true
                break
              end
            end

            if !hasmapall
              opts[:bsd__nfs_options] << "mapall=#{opts[:map_uid]}:#{opts[:map_gid]}"
            end

            opts[:bsd__compiled_nfs_options] = opts[:bsd__nfs_options].map do |opt|
              "-#{opt}"
            end.join(" ")
          end

          logger.info("Exporting the following for NFS...")
          dirmap.each do |dirs, opts|
            logger.info("NFS DIR: #{dirs.inspect}")
            logger.info("NFS OPTS: #{opts.inspect}")
          end

          output = Vagrant::Util::TemplateRenderer.render(nfs_exports_template,
                                           uuid: id,
                                           ips: ips,
                                           folders: dirmap,
                                           user: Process.uid)

          # The sleep ensures that the output is truly flushed before any `sudo`
          # commands are issued.
          ui.info I18n.t("vagrant.hosts.bsd.nfs_export")
          sleep 0.5

          # First, clean up the old entry
          nfs_cleanup(id)

          # Only use "sudo" if we can't write to /etc/exports directly
          sudo_command = ""
          sudo_command = "sudo " if !File.writable?("/etc/exports")

          # Output the rendered template into the exports
          output.split("\n").each do |line|
            line = Vagrant::Util::ShellQuote.escape(line, "'")
            system(
              "echo '#{line}' | " +
              "#{sudo_command}/usr/bin/tee -a /etc/exports >/dev/null")
          end

          # We run restart here instead of "update" just in case nfsd
          # is not starting
          system(*nfs_restart_command)
        end

        def self.nfs_exports_template(environment)
          "nfs/exports_bsd"
        end

        def self.nfs_installed(environment)
          !!Vagrant::Util::Which.which("nfsd")
        end

        def self.nfs_prune(environment, ui, valid_ids)
          return if !File.exist?("/etc/exports")

          logger = Log4r::Logger.new("vagrant::hosts::bsd")
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
                  ui.info I18n.t("vagrant.hosts.bsd.nfs_prune")
                  output = true
                end

                logger.info("Invalid ID, pruning: #{id}")
                nfs_cleanup(id)
              end
            end
          end
        rescue Errno::EACCES
          raise Vagrant::Errors::NFSCantReadExports
        end

        def self.nfs_restart_command(environment)
          ["sudo", "nfsd", "restart"]
        end

        protected

        def self.nfs_cleanup(id)
          return if !File.exist?("/etc/exports")

          # Escape sed-sensitive characters:
          id = id.gsub("/", "\\/")
          id = id.gsub(".", "\\.")

          user = Process.uid

          command = []
          command << "sudo" if !File.writable?("/etc/exports")
          command += [
            "sed", "-E", "-e",
            "/^# VAGRANT-BEGIN:( #{user})? #{id}/," +
            "/^# VAGRANT-END:( #{user})? #{id}/ d",
            "-ibak",
            "/etc/exports"
          ]

          # Use sed to just strip out the block of code which was inserted
          # by Vagrant, and restart NFS.
          system(*command)
        end

        def self.nfs_checkexports!
          r = Vagrant::Util::Subprocess.execute("nfsd", "checkexports")
          if r.exit_code != 0
            raise Vagrant::Errors::NFSBadExports, output: r.stderr
          end
        end

        def self.nfs_check_folders_for_apfs(folders)
          folders.each do |_, opts|
            # check to see if this path is mounted in an APFS filesystem, and if it's under the
            # firmlink which must be prefixed. we need to use the OS X df — GNU won't notice.
            is_mounted_apfs_command = "/bin/df -t apfs #{opts[:hostpath]}"
            result = Vagrant::Util::Subprocess.execute(*Shellwords.split(is_mounted_apfs_command))
            if (result.stdout.include? OSX_FIRMLINK_HACK)
              opts[:hostpath].prepend(OSX_FIRMLINK_HACK)
            end
          end
        end
      end
    end
  end
end
