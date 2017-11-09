require_relative "../../../synced_folders/rsync/default_unix_cap"

module VagrantPlugins
  module GuestMINIX
    module Cap
      class RSync
        extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap

        def self.rsync_install(machine)
          machine.communicate.sudo(
            'yes | pkgin update && yes | pkgin install rsync'
          )
        end

        def self.rsync_command(machine)
          'su root -c rsync'
        end
      end
    end
  end
end
