require_relative "../../../synced_folders/rsync/default_unix_cap"

module VagrantPlugins
  module GuestSolaris11
    module Cap
      class RSync
        extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap

        def self.rsync_command(machine)
          "#{machine.config.solaris11.suexec_cmd} rsync"
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{opts[:guestpath]}'")
          end
        end

        def self.rsync_post(machine, opts)
          if opts.key?(:chown) && !opts[:chown]
            return
          end
          suexec_cmd = machine.config.solaris11.suexec_cmd
          machine.communicate.execute("#{suexec_cmd} #{build_rsync_chown(opts)}")
        end
      end
    end
  end
end
