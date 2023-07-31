# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Action
    module Builtin
      # This module enables MixinSyncedFolder for server mode
      module Remote

        module MixinSyncedFolders
          # Add an attribute accesor for the basis_client
          # when applied to the MixinSyncedFolders class
          def self.prepended(klass)
            klass.class_eval do
              attr_accessor :basis_client
            end
          end

          # This should never be called?
          def default_synced_folder_type(machine, plugins)
            nil
          end

          # Synced folder management happens on the vagrant server. 
          # Do nothing here
          def save_synced_folders(machine, folders, opts={})
            nil
          end

          # This returns the set of shared folders that should be done for
          # this machine. It returns the folders in a hash keyed by the
          # implementation class for the synced folders.
          #
          # @return [Hash<Symbol, Hash<String, Hash>>]
          def synced_folders(machine, **opts)
            machine.synced_folders
          end
        end
      end
    end
  end
end
