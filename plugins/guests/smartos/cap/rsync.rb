require_relative "../../../synced_folders/rsync/default_unix_cap"

module VagrantPlugins
  module GuestSmartos
    module Cap
      class RSync
        extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap

        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_command(machine)
          "#{machine.config.smartos.suexec_cmd} rsync"
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.execute("#{machine.config.smartos.suexec_cmd} mkdir -p '#{opts[:guestpath]}'")
          end
        end

        def self.rsync_post(machine, opts)
          if opts.key?(:chown) && !opts[:chown]
            return
          end
          suexec_cmd = machine.config.smartos.suexec_cmd
          machine.communicate.execute("#{suexec_cmd} #{build_rsync_chown(opts)}")
        end
      end
    end
  end
end
