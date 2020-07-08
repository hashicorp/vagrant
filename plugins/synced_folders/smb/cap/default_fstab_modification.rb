module VagrantPlugins
  module SyncedFolderSMB
    module Cap
      module DefaultFstabModification
        def self.default_fstab_modification(machine)
          return false
        end
      end
    end
  end
end
