module VagrantPlugins
  module CommandServe
    module Service
      autoload :CapabilityPlatformService, Vagrant.source_root.join("plugins/commands/serve/service/capability_platform_service").to_s
      autoload :CommandService, Vagrant.source_root.join("plugins/commands/serve/service/command_service").to_s
      autoload :GuestService, Vagrant.source_root.join("plugins/commands/serve/service/guest_service").to_s
      autoload :HostService, Vagrant.source_root.join("plugins/commands/serve/service/host_service").to_s
      autoload :InternalService, Vagrant.source_root.join("plugins/commands/serve/service/internal_service").to_s
      autoload :ProviderService, Vagrant.source_root.join("plugins/commands/serve/service/provider_service").to_s

      class ServiceInfo
        # @return [String] Name of requested plugin
        attr_reader :plugin_name

        def initialize(plugin_name: nil)
          @plugin_name = plugin_name
        end

        def self.info
          info = Thread.current.thread_variable_get(:service_info)
          if info.nil?
            raise ArgumentError,
              "Service information has not been set!"
          end
          info
        end

        def self.with_info(context)
          info = new(plugin_name: context.metadata["plugin_name"])
          Thread.current.thread_variable_set(:service_info, info)
          return if !block_given?
          begin
            yield info
          ensure
            Thread.current.thread_variable_set(:service_info, nil)
          end
        end
      end
    end
  end
end
