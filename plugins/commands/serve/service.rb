require "ostruct"

module VagrantPlugins
  module CommandServe
    module Service
      autoload :CapabilityPlatformService, Vagrant.source_root.join("plugins/commands/serve/service/capability_platform_service").to_s
      autoload :CommandService, Vagrant.source_root.join("plugins/commands/serve/service/command_service").to_s
      autoload :CommunicatorService, Vagrant.source_root.join("plugins/commands/serve/service/communicator_service").to_s
      autoload :GuestService, Vagrant.source_root.join("plugins/commands/serve/service/guest_service").to_s
      autoload :HostService, Vagrant.source_root.join("plugins/commands/serve/service/host_service").to_s
      autoload :InternalService, Vagrant.source_root.join("plugins/commands/serve/service/internal_service").to_s
      autoload :ProviderService, Vagrant.source_root.join("plugins/commands/serve/service/provider_service").to_s
      autoload :SyncedFolderService, Vagrant.source_root.join("plugins/commands/serve/service/synced_folder_service").to_s

      class ServiceInfo < OpenStruct

        def initialize(plugin_name: nil, broker: nil)
          super()
          self.plugin_name = plugin_name.to_sym if plugin_name
          self.broker = broker
        end

        def self.info
          info = Thread.current.thread_variable_get(:service_info)
          if info.nil?
            raise ArgumentError,
              "Service information has not been set!"
          end
          info
        end

        def self.with_info(context, broker: nil)
          raise NotImplementedError
        end
      end
    end
  end
end
