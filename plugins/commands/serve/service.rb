# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "ostruct"

module VagrantPlugins
  module CommandServe
    module Service
      class << self
        def method_missing(name, *args)
          if name == :ProtoService
            return protoService(*args)
          end
          super
        end

        def protoService(klass)
          Class.new(klass) do
            [Util::FuncSpec::Service,
              Util::HasLogger,
              Util::HasMapper,
              Util::HasSeeds::Service,
              Util::NamedPlugin::Service,
              Util::ServiceInfo,
              Util::ExceptionTransformer].each { |m| include m }

            attr_reader :broker

            def initialize(broker:)
              if broker.nil?
                raise ArgumentError,
                  "Broker must be provided"
              end
              @broker = broker
            end

            def cache
              CommandServe.cache
            end
          end
        end
      end

      autoload :CapabilityPlatformService, Vagrant.source_root.join("plugins/commands/serve/service/capability_platform_service").to_s
      autoload :CommandService, Vagrant.source_root.join("plugins/commands/serve/service/command_service").to_s
      autoload :CommunicatorService, Vagrant.source_root.join("plugins/commands/serve/service/communicator_service").to_s
      autoload :ConfigService, Vagrant.source_root.join("plugins/commands/serve/service/config_service").to_s
      autoload :GuestService, Vagrant.source_root.join("plugins/commands/serve/service/guest_service").to_s
      autoload :HostService, Vagrant.source_root.join("plugins/commands/serve/service/host_service").to_s
      autoload :InternalService, Vagrant.source_root.join("plugins/commands/serve/service/internal_service").to_s
      autoload :ProviderService, Vagrant.source_root.join("plugins/commands/serve/service/provider_service").to_s
      autoload :ProvisionerService, Vagrant.source_root.join("plugins/commands/serve/service/provisioner_service").to_s
      autoload :SyncedFolderService, Vagrant.source_root.join("plugins/commands/serve/service/synced_folder_service").to_s
      autoload :PushService, Vagrant.source_root.join("plugins/commands/serve/service/push_service").to_s

      class ServiceInfo < OpenStruct
        class << self
          attr_reader :manager_tracker
        end

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

        @manager_tracker = Util::UsageTracker.new
      end
    end
  end
end
