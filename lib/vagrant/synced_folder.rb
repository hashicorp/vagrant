require "vagrant/capability_host"

module Vagrant
  # This class handles host-OS specific interactions. It is responsible for
  # detecting the proper host OS implementation and delegating capabilities
  # to plugins.
  #
  # See {Guest} for more information on capabilities.
  class SyncedFolder
    include CapabilityHost

    def initialize(synced_folder, synced_folders, capabilities, env)
      initialize_capabilities!(synced_folder, synced_folders, capabilities, env)
    end
  end
end
