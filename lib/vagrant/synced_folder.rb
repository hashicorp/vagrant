require "vagrant/capability_host"

module Vagrant
  # This class handles host-OS specific interactions. It is responsible for
  # detecting the proper host OS implementation and delegating capabilities
  # to plugins.
  #
  # See {Guest} for more information on capabilities.
  class SyncedFolder
    include CapabilityHost

    def initialize(synced_folder_type, synced_folders, capabilities, machine)
      if synced_folder_type.nil?
        synced_folder_type = default_synced_folder_type(machine, synced_folders)
      end
      initialize_capabilities!(synced_folder_type, synced_folders, capabilities, machine)
    end

    # This goes over all the registered synced folder types and returns
    # the highest priority implementation that is usable for this machine.
    def default_synced_folder_type(machine, plugins)
      ordered = []

      # First turn the plugins into an array
      plugins.each do |key, data|
        impl     = data[0]
        priority = data[1]

        ordered << [priority, key, impl]
      end

      # Order the plugins by priority. Higher is tried before lower.
      ordered = ordered.sort { |a, b| b[0] <=> a[0] }

      allowed_types = machine.config.vm.allowed_synced_folder_types
      if allowed_types
        ordered = allowed_types.map do |type|
          ordered.find do |_, key, impl|
            key == type
          end
        end.compact
      end

      # Find the proper implementation
      ordered.each do |_, key, impl|
        return key if impl.new.usable?(machine)
      end

      return nil
    end
  end
end
