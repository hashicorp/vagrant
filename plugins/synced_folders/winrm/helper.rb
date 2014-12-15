require "vagrant/util/platform"
require "vagrant/util/subprocess"

module VagrantPlugins
  module SyncedFolderWinRM
    # This is a helper that abstracts out the functionality of syncing
    # folders over winrm so that it can be called from anywhere.
    class WinRMHelper
      # This converts an exclude pattern to a regular expression
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

      def self.winrm_single(machine, winrm_info, opts)
        # Folder info
        guestpath = opts[:guestpath]
        hostpath  = opts[:hostpath]
        hostpath  = File.expand_path(hostpath, machine.env.root_path)
        hostpath  = Vagrant::Util::Platform.fs_real_path(hostpath).to_s

        # WinRM probably doesn't need cygwin_path like rsync.
        # if Vagrant::Util::Platform.windows?
          # winrm for Windows expects cygwin style paths, always.
          # hostpath = Vagrant::Util::Platform.cygwin_path(hostpath)
        # end

        # Make sure the host path ends with a "/" to avoid creating
        # a nested directory...
        if !hostpath.end_with?("/")
          hostpath += "/"
        end

        # Folder options
        opts[:owner] ||= winrm_info[:username]
        opts[:group] ||= winrm_info[:username]

        # Connection information
        username = winrm_info[:username]
        host     = winrm_info[:host]

        # Exclude some files by default, and any that might be configured
        # by the user.
        excludes = ['.vagrant/']
        excludes += Array(opts[:exclude]).map(&:to_s) if opts[:exclude]
        excludes.uniq!

        # The working directory should be the root path
        command_opts = {}
        command_opts[:workdir] = machine.env.root_path.to_s

        machine.ui.info(I18n.t(
          "vagrant_winrm.winrm_folder", guestpath: guestpath, hostpath: hostpath))
        if excludes.length > 1
          machine.ui.info(I18n.t(
            "vagrant_winrm.winrm_folder_excludes", excludes: excludes.inspect))
        end

        # If we have tasks to do before winrming, do those.
        if machine.guest.capability?(:winrm_pre)
          machine.guest.capability(:winrm_pre, opts)
        end

        shell = machine.communicate.shell # FIXME: Hacky!
        file_manager = VagrantPlugins::CommunicatorWinRM::FileManager.new(shell)
        file_manager.upload(hostpath, guestpath)

        # If we have tasks to do after winrming, do those.
        if machine.guest.capability?(:winrm_post)
          machine.guest.capability(:winrm_post, opts)
        end
      end
    end
  end
end
