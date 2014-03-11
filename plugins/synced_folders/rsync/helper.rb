require "vagrant/util/platform"
require "vagrant/util/subprocess"

module VagrantPlugins
  module SyncedFolderRSync
    # This is a helper that abstracts out the functionality of rsyncing
    # folders so that it can be called from anywhere.
    class RsyncHelper
      def self.rsync_single(machine, ssh_info, opts)
        # Folder info
        guestpath = opts[:guestpath]
        hostpath  = opts[:hostpath]
        hostpath  = File.expand_path(hostpath, machine.env.root_path)
        hostpath  = Vagrant::Util::Platform.fs_real_path(hostpath).to_s

        if Vagrant::Util::Platform.windows?
          # rsync for Windows expects cygwin style paths, always.
          hostpath = Vagrant::Util::Platform.cygwin_path(hostpath)
        end

        # Make sure the host path ends with a "/" to avoid creating
        # a nested directory...
        if !hostpath.end_with?("/")
          hostpath += "/"
        end

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

        # Get the command-line arguments
        args = nil
        args = Array(opts[:args]) if opts[:args]
        args ||= ["--verbose", "--archive", "--delete", "-z"]

        # Build up the actual command to execute
        command = [
          "rsync",
          args,
          "-e", rsh,
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
        else
          if opts[:owner] || opts[:group]
            group = opts[:group] ? ":#{folder_opts[:group]}" : ''

            machine.communicate.tap do |comm|
              comm.sudo("chown -R #{opts[:owner]}#{group} '#{guestpath}'")
            end
          end
        end
      end
    end
  end
end
