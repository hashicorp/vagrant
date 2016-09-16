require_relative "../../../synced_folders/rsync/default_unix_cap"

module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class RSync
        extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap

        def self.rsync_install(machine)
          machine.communicate.sudo(
            'PKG_PATH="http://ftp.openbsd.org/pub/OpenBSD/' \
            '`uname -r`/packages/`arch -s`/" ' \
            'pkg_add -I rsync--')
        end
      end
    end
  end
end
