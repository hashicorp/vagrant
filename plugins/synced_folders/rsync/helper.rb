require "vagrant/util/platform"
require "vagrant/util/subprocess"

module VagrantPlugins
  module SyncedFolderRSync
    # This is a helper that abstracts out the functionality of rsyncing
    # folders so that it can be called from anywhere.
    class RsyncHelper
      def initialize(machine, ssh_info, opts)
        @machine = machine

        @opts = normalize_opts(opts, ssh_info)

        @guestpath = guestpath
        @hostpath = hostpath
        @excludes = excludes

        @rsync_command = rsync_command(ssh_info)
        @rsync_command_opts = rsync_command_opts

        @first_sync_done = false
      end

      def rsync_single
        log_info

        # If we have tasks to do before rsyncing, do those.
        if !skip_rsync_pre? && @machine.guest.capability?(:rsync_pre)
          @machine.guest.capability(:rsync_pre, @opts)
        end

        subprocess = if verbose?
          Vagrant::Util::Subprocess.execute(*(@rsync_command + [@rsync_command_opts])) {
            |io_name,data| data.each_line { |line|
              @machine.ui.info("rsync[#{io_name}] -> #{line}") }
          }
        else
          Vagrant::Util::Subprocess.execute(*(@rsync_command + [@rsync_command_opts]))
        end

        if subprocess.exit_code != 0
          raise Vagrant::Errors::RSyncError,
            command: @rsync_command.join(" "),
            guestpath: @guestpath,
            hostpath: @hostpath,
            stderr: subprocess.stderr
        end

        # If we have tasks to do after rsyncing, do those.
        if !skip_rsync_post? && @machine.guest.capability?(:rsync_post)
          @machine.guest.capability(:rsync_post, @opts)
        end

        @first_sync_done = true
      end

      # This converts an rsync exclude pattern to a regular expression
      # we can send to Listen.
      def self.exclude_to_regexp(path, exclude)
        start_anchor = false

        if exclude.start_with?("/")
          start_anchor = true
          exclude      = exclude[1..-1]
        end

        path   = "#{path}/" if !path.end_with?("/")
        regexp = "^#{Regexp.escape(path)}"
        regexp += ".*" if !start_anchor

        # This is REALLY ghetto, but its a start. We can improve and
        # keep unit tests passing in the future.
        exclude = exclude.gsub("**", "|||GLOBAL|||")
        exclude = exclude.gsub("*", "|||PATH|||")
        exclude = exclude.gsub("|||PATH|||", "[^/]*")
        exclude = exclude.gsub("|||GLOBAL|||", ".*")
        regexp += exclude

        Regexp.new(regexp)
      end

      def self.rsync_single(machine, ssh_info, opts)
        machine.ui.warn("WARNING: `VagrantPlugins::SyncedFolderRSync::RsyncHelper.rsync_single`")
        machine.ui.warn("is a deprecated internal API. Please use an instance of that class instead.")

        instance = new(machine, ssh_info, opts)
        instance.rsync_single
      end

      private

      def verbose?
        @opts.include?(:verbose)
      end

      def normalize_opts(opts, ssh_info)
        # Folder options
        opts[:owner] ||= ssh_info[:username]
        opts[:group] ||= ssh_info[:username]

        opts
      end

      def guestpath
        # if the guest has a guest path scrubber capability, use it
        if @machine.guest.capability?(:rsync_scrub_guestpath)
          @machine.guest.capability(:rsync_scrub_guestpath, @opts)
        else
          @opts[:guestpath]
        end
      end

      def hostpath
        hostpath = @opts[:hostpath]
        hostpath = File.expand_path(hostpath, @machine.env.root_path)
        hostpath = Vagrant::Util::Platform.fs_real_path(hostpath).to_s

        if Vagrant::Util::Platform.windows?
          # rsync for Windows expects cygwin style paths, always.
          hostpath = Vagrant::Util::Platform.cygwin_path(hostpath)
        end

        # Make sure the host path ends with a "/" to avoid creating
        # a nested directory...
        if !hostpath.end_with?("/")
          hostpath += "/"
        end

        hostpath
      end

      # Builds up the actual command to execute
      def rsync_command(ssh_info)
        [
          "rsync",
          rsync_args,
          "-e", rsync_ssh_command(ssh_info),
          @excludes.map { |e| ["--exclude", e] },
          @hostpath,
          "#{ssh_connection_info(ssh_info)}:#{@guestpath}",
        ].flatten
      end

      def rsync_ssh_command(ssh_info)
        # Create the path for the control sockets. We used to do this
        # in the machine data dir but this can result in paths that are
        # too long for unix domain sockets.
        controlpath = File.join(Dir.tmpdir, "ssh.#{rand(1000)}")

        [
          "ssh -p #{ssh_info[:port]} " +
          proxy_command(ssh_info) +
          "-o ControlMaster=auto " +
          "-o ControlPath=#{controlpath} " +
          "-o ControlPersist=10m " +
          "-o StrictHostKeyChecking=no " +
          "-o IdentitiesOnly=true " +
          "-o UserKnownHostsFile=/dev/null",
          private_key_paths(ssh_info),
        ].flatten.join(' ')
      end

      def proxy_command(ssh_info)
        if ssh_info[:proxy_command]
          "-o ProxyCommand='#{ssh_info[:proxy_command]}' "
        else
          ''
        end
      end

      def private_key_paths(ssh_info)
        ssh_info[:private_key_path].map { |p| "-i '#{p}'" }
      end

      def ssh_connection_info(ssh_info)
        username = ssh_info[:username]
        host     = ssh_info[:host]

        "#{username}@#{host}"
      end

      # Exclude some files by default, and any that might be configured
      # by the user.
      def excludes
        excludes = ['.vagrant/']
        excludes += Array(@opts[:exclude]).map(&:to_s) if @opts[:exclude]
        excludes.uniq
      end

      # Builds the command-line arguments for rsync
      def rsync_args
        args = nil
        args = Array(@opts[:args]).dup if @opts[:args]
        args ||= ['--verbose', '--archive', '--delete', '-z', '--copy-links']

        # On Windows, we have to set a default chmod flag to avoid permission issues
        if Vagrant::Util::Platform.windows? && !args.any? { |arg| arg.start_with?('--chmod=') }
          # Ensures that all non-masked bits get enabled
          args << '--chmod=ugo=rwX'

          # Remove the -p option if --archive is enabled (--archive equals -rlptgoD)
          # otherwise new files will not have the destination-default permissions
          args << '--no-perms' if args.include?('--archive') || args.include?('-a')
        end

        # Disable rsync's owner/group preservation (implied by --archive) unless
        # specifically requested, since we adjust owner/group to match shared
        # folder setting ourselves.
        args << '--no-owner' unless args.include?('--owner') || args.include?('-o')
        args << '--no-group' unless args.include?('--group') || args.include?('-g')

        # Tell local rsync how to invoke remote rsync with sudo
        rsync_path = @opts[:rsync_path]
        if !rsync_path && @machine.guest.capability?(:rsync_command)
          rsync_path = @machine.guest.capability(:rsync_command)
        end
        if rsync_path
          args << "--rsync-path"<< rsync_path
        end

        args
      end

      def rsync_command_opts
        # The working directory should be the root path
        command_opts = {}
        command_opts[:workdir] = @machine.env.root_path.to_s

        if verbose?
          command_opts[:notify] = [:stdout, :stderr]
        end

        command_opts
      end

      def log_info
        @machine.ui.info(I18n.t(
          "vagrant.rsync_folder", guestpath: @guestpath, hostpath: @hostpath))
        if excludes.length > 1
          @machine.ui.info(I18n.t(
            "vagrant.rsync_folder_excludes", excludes: @excludes.inspect))
        end
        if verbose?
          @machine.ui.info(I18n.t("vagrant.rsync_showing_output"));
        end
      end

      def skip_rsync_pre?
        @opts[:skip_rsync_pre] || @first_sync_done && @opts[:skip_rsync_pre_after_first_sync]
      end

      def skip_rsync_post?
        @opts[:skip_rsync_post] || @first_sync_done && @opts[:skip_rsync_post_after_first_sync]
      end
    end
  end
end
