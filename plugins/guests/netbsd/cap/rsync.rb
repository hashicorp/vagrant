require_relative "../../../synced_folders/rsync/default_unix_cap"

module VagrantPlugins
  module GuestNetBSD
    module Cap
      class RSync
        extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap

        def self.rsync_install(machine)
          machine.communicate.sudo(
            'PATH=$PATH:/usr/sbin '\
              'PKG_PATH="http://ftp.NetBSD.org/pub/pkgsrc/packages/NetBSD/' \
              '`uname -m`/`uname -r | cut -d. -f1-2`/All" ' \
              'pkg_add rsync'
          )
        end
      end
    end
  end
end
