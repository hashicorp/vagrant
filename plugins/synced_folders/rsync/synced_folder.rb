require "log4r"

require "vagrant/util/subprocess"
require "vagrant/util/which"

module VagrantPlugins
  module SyncedFolderRSync
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      include Vagrant::Util

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::synced_folders::rsync")
      end

      def usable?(machine, raise_error=false)
        rsync_path = Which.which("rsync")
        return true if rsync_path
        return false if !raise_error
        raise Vagrant::Errors::RSyncNotFound
      end

      def prepare(machine, folders, opts)
        # Nothing is necessary to do before VM boot.
      end

      def enable(machine, folders, opts)
        ssh_info = machine.ssh_info

        folders.each do |id, folder_opts|
          rsync_single(machine, ssh_info, folder_opts)
        end
      end

      # rsync_single rsync's a single folder with the given options.
      def rsync_single(machine, ssh_info, opts)
        # Folder info
        guestpath = opts[:guestpath]
        hostpath  = opts[:hostpath]

        # Connection information
        username = ssh_info[:username]
        host     = ssh_info[:host]
        rsh = [
          "ssh -p #{ssh_info[:port]} -o StrictHostKeyChecking=no",
          ssh_info[:private_key_path].map { |p| "-i '#{p}'" },
        ].flatten.join(" ")

        # Exclude some files by default, and any that might be configured
        # by the user.
        excludes = ['.vagrant/']
        excludes += Array(opts[:exclude]).map(&:to_s) if opts[:exclude]
        excludes.uniq!

        # Build up the actual command to execute
        command = [
          "rsync",
          "--verbose",
          "--archive",
          "-z",
          excludes.map { |e| ["--exclude", e] },
          "-e", rsh,
          hostpath,
          "#{username}@#{host}:#{guestpath}"
        ].flatten
        command_opts = {}

        # The working directory should be the root path
        command_opts[:workdir] = machine.env.root_path.to_s

        machine.ui.info(I18n.t(
          "vagrant.rsync_folder", guestpath: guestpath, hostpath: hostpath))
        if excludes.length > 1
          machine.ui.info(I18n.t(
            "vagrant.rsync_folder_excludes", excludes: excludes.inspect))
        end

        # If we have tasks to do before rsyncing, do those.
        if machine.guest.capability?(:rsync_pre)
          machine.guest.capability(:rsync_pre, opts)
        end

        r = Vagrant::Util::Subprocess.execute(*(command + [command_opts]))
        if r.exit_code != 0
          raise Vagrant::Errors::RSyncError,
            command: command.join(" "),
            guestpath: guestpath,
            hostpath: hostpath,
            stderr: r.stderr
        end
      end
    end
  end
end
