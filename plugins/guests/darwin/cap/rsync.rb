require_relative "../../../synced_folders/rsync/default_unix_cap"

module VagrantPlugins
  module GuestDarwin
    module Cap
      class RSync
        extend VagrantPlugins::SyncedFolderRSync::DefaultUnixCap
      end
    end
  end
end
