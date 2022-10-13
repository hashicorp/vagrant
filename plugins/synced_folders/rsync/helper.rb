require "fileutils"
require "ipaddr"
require "shellwords"
require "tmpdir"

require "vagrant/util/platform"
require "vagrant/util/subprocess"

module VagrantPlugins
  module SyncedFolderRSync
    # This is a helper that abstracts out the functionality of rsyncing
    # folders so that it can be called from anywhere.
    class RsyncHelper
      # rsync version requirement to support chown argument
      RSYNC_CHOWN_REQUIREMENT = Gem::Requirement.new(">= 3.1.0").freeze

      # This converts an rsync exclude pattern to a regular expression
      # we can send to Listen.
      #
      # Note: Listen expects a path relative to the parameter passed into the
      # Listener, not a fully qualified path
      #
      # @param [String]  - exclude path
      # @return [Regexp] - A regex of the path, modified, to exclude
      def self.exclude_to_regexp(exclude)
        start_anchor = false

        if exclude.start_with?("/")
          start_anchor = true
          exclude      = exclude[1..-1]
        end

        exclude = "#{exclude}/" if !exclude.end_with?("/")
        exclude = "^#{exclude}"
        exclude += ".*" if !start_anchor

        # This is not an ideal solution, but it's a start. We can improve and
        # keep unit tests passing in the future.
        exclude = exclude.gsub("**", "|||GLOBAL|||")
        exclude = exclude.gsub("*", "|||PATH|||")
        exclude = exclude.gsub("|||PATH|||", "[^/]*")
        exclude = exclude.gsub("|||GLOBAL|||", ".*")

        Regexp.new(exclude)
      end

      def self.rsync_single(machine, ssh_info, opts)
        # Folder info
        guestpath = opts[:guestpath]
        hostpath  = opts[:hostpath]
        hostpath  = File.expand_path(hostpath, machine.env.root_path)
        hostpath  = Vagrant::Util::Platform.fs_real_path(hostpath).to_s

        # if the guest has a guest path scrubber capability, use it
        if machine.guest.capability?(:rsync_scrub_guestpath)
          guestpath = machine.guest.capability(:rsync_scrub_guestpath, opts)
        end

        # Shellescape
        guestpath = Shellwords.escape(guestpath)

        if Vagrant::Util::Platform.windows?
          # rsync for Windows expects cygwin style paths, always.
          hostpath = Vagrant::Util::Platform.cygwin_path(hostpath)
        end

        # Make sure the host path ends with a "/" to avoid creating
        # a nested directory...
        if !hostpath.end_with?("/")
          hostpath += "/"
        end

        # Folder options
        opts[:owner] ||= ssh_info[:username]
        opts[:group] ||= ssh_info[:username]

        # set log level
        log_level = ssh_info[:log_level] || "FATAL"

        # Connection information
        # make it better match lib/vagrant/util/ssh.rb command_options style and logic
        username = ssh_info[:username]
        host     = ssh_info[:host]
        proxy_command = ""
        if ssh_info[:proxy_command]
          proxy_command = "-o ProxyCommand='#{ssh_info[:proxy_command]}' "
        end

        ssh_config_file = ""
        if ssh_info[:config]
          ssh_config_file = "-F #{ssh_info[:config]}"
        end

        # Create the path for the control sockets. We used to do this
        # in the machine data dir but this can result in paths that are
        # too long for unix domain sockets.
        control_options = ""
        unless Vagrant::Util::Platform.windows?
          controlpath = Dir.mktmpdir("vagrant-rsync-")
          control_options = "-o ControlMaster=auto -o ControlPath=#{controlpath} -o ControlPersist=10m "
        end

        # rsh cmd option
        rsh = [
          "ssh", "-p", "#{ssh_info[:port]}",
          "-o", "LogLevel=#{log_level}",
          proxy_command,
          ssh_config_file,
          control_options,
        ]

        # Solaris/OpenSolaris/Illumos uses SunSSH which doesn't support the
        # IdentitiesOnly option. Also, we don't enable it if keys_only is false
        # so that SSH properly searches our identities and tries to do it itself.
        if !Vagrant::Util::Platform.solaris? && ssh_info[:keys_only]
          rsh += ["-o", "IdentitiesOnly=yes"]
        end

        # no strict hostkey checking unless paranoid
        if ssh_info[:verify_host_key] == :never || !ssh_info[:verify_host_key]
          rsh += [
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null"]
        end

        # If specified, attach the private key paths.
        if ssh_info[:private_key_path]
          rsh += ssh_info[:private_key_path].map { |p| "-i '#{p}'" }
        end

        # Exclude some files by default, and any that might be configured
        # by the user.
        excludes = ['.vagrant/']
        excludes += Array(opts[:exclude]).map(&:to_s) if opts[:exclude]
        excludes.uniq!

        # Get the command-line arguments
        args = nil
        args = Array(opts[:args]).dup if opts[:args]
        args ||= ["--verbose", "--archive", "--delete", "-z", "--copy-links"]

        # On Windows, we have to set a default chmod flag to avoid permission issues
        if Vagrant::Util::Platform.windows? && !args.any? { |arg| arg.start_with?("--chmod=") }
          # Ensures that all non-masked bits get enabled
          args << "--chmod=ugo=rwX"

          # Remove the -p option if --archive is enabled (--archive equals -rlptgoD)
          # otherwise new files will not have the destination-default permissions
          args << "--no-perms" if args.include?("--archive") || args.include?("-a")
        end

        if opts[:rsync_ownership] && rsync_chown_support?(machine)
          # Allow rsync to map ownership
          args << "--chown=#{opts[:owner]}:#{opts[:group]}"
          # Notify rsync post capability not to chown
          opts[:chown] = false
        else
          # Disable rsync's owner/group preservation (implied by --archive) unless
          # specifically requested, since we adjust owner/group to match shared
          # folder setting ourselves.
          args << "--no-owner" unless args.include?("--owner") || args.include?("-o")
          args << "--no-group" unless args.include?("--group") || args.include?("-g")
        end

        # Tell local rsync how to invoke remote rsync with sudo
        rsync_path = opts[:rsync_path]
        if !rsync_path && machine.guest.capability?(:rsync_command)
          rsync_path = machine.guest.capability(:rsync_command)
        end
        if rsync_path
          args << "--rsync-path"<< rsync_path
        end

        # If the remote host is an IPv6 address reformat
        begin
          if IPAddr.new(host).ipv6?
            host = "[#{host}]"
          end
        rescue IPAddr::Error
          # Ignore
        end

        # Build up the actual command to execute
        command = [
          "rsync",
          args,
          "-e", rsh.flatten.join(" "),
          excludes.map { |e| ["--exclude", e] },
          hostpath,
          "#{username}@#{host}:#{guestpath}",
        ].flatten

        # The working directory should be the root path
        command_opts = {}
        command_opts[:workdir] = machine.env.root_path.to_s

        machine.ui.info(I18n.t(
          "vagrant.rsync_folder", guestpath: guestpath, hostpath: hostpath))
        if excludes.length > 1
          machine.ui.info(I18n.t(
            "vagrant.rsync_folder_excludes", excludes: excludes.inspect))
        end
        if opts.include?(:verbose)
          machine.ui.info(I18n.t("vagrant.rsync_showing_output"));
        end

        # If we have tasks to do before rsyncing, do those.
        if machine.guest.capability?(:rsync_pre)
          machine.guest.capability(:rsync_pre, opts)
        end

        if opts.include?(:verbose)
          command_opts[:notify] = [:stdout, :stderr]
          r = Vagrant::Util::Subprocess.execute(*(command + [command_opts])) {
            |io_name,data| data.each_line { |line|
              machine.ui.info("rsync[#{io_name}] -> #{line}") }
          }
        else
          r = Vagrant::Util::Subprocess.execute(*(command + [command_opts]))
        end

        if r.exit_code != 0
          raise Vagrant::Errors::RSyncError,
            command: command.map(&:inspect).join(" "),
            guestpath: guestpath,
            hostpath: hostpath,
            stderr: r.stderr
        end

        # If we have tasks to do after rsyncing, do those.
        if machine.guest.capability?(:rsync_post)
          begin
            machine.guest.capability(:rsync_post, opts)
          rescue Vagrant::Errors::VagrantError => err
            raise Vagrant::Errors::RSyncPostCommandError,
              guestpath: guestpath,
              hostpath: hostpath,
              message: err.to_s
          end
        end
      ensure
        FileUtils.remove_entry_secure(controlpath, true) if controlpath
      end

      # Check if rsync versions support using chown option
      #
      # @param [Vagrant::Machine] machine The remote machine
      # @return [Boolean]
      def self.rsync_chown_support?(machine)
        if !RSYNC_CHOWN_REQUIREMENT.satisfied_by?(Gem::Version.new(local_rsync_version))
          return false
        end
        mrv = machine_rsync_version(machine)
        if mrv && !RSYNC_CHOWN_REQUIREMENT.satisfied_by?(Gem::Version.new(mrv))
          return false
        end
        true
      end

      # @return [String, nil] version of remote rsync
      def self.machine_rsync_version(machine)
        if machine.guest.capability?(:rsync_command)
          rsync_path = machine.guest.capability(:rsync_command)
        else
          rsync_path = "rsync"
        end
        output = ""
        machine.communicate.execute(rsync_path + " --version") { |_, data| output << data }
        vmatch = output.match(/version\s+(?<version>[\d.]+)\s/)
        if vmatch
          vmatch[:version]
        end
      end

      # @return [String, nil] version of local rsync
      def self.local_rsync_version
        if !@_rsync_version
          r = Vagrant::Util::Subprocess.execute("rsync", "--version")
          vmatch = r.stdout.to_s.match(/version\s+(?<version>[\d.]+)\s/)
          if vmatch
            @_rsync_version = vmatch[:version]
          end
        end
        @_rsync_version
      end

      # @private
      # Reset the cached values for helper. This is not considered a public
      # API and should only be used for testing.
      def self.reset!
        instance_variables.each(&method(:remove_instance_variable))
      end
    end
  end
end
