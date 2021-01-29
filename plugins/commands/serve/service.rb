module VagrantPlugins
  module CommandServe
    module Service
      # Simple aliases
      SDK = Hashicorp::Vagrant::Sdk
      SRV = Hashicorp::Vagrant

      autoload :CommandService, Vagrant.source_root.join("plugins/commands/serve/service/command_service").to_s
      autoload :HostService, Vagrant.source_root.join("plugins/commands/serve/service/host_service").to_s
      autoload :InternalService, Vagrant.source_root.join("plugins/commands/serve/service/internal_service").to_s
      autoload :ProviderService, Vagrant.source_root.join("plugins/commands/serve/service/provider_service").to_s

      class ServiceInfo
        class ClientInterceptor < GRPC::ClientInterceptor
          def request_response(request:, call:, method:, metadata: {})
            metadata["client-version"] = "Vagrant/#{Vagrant::VERSION}"
            metadata["client-api-protocol"] = "1,1"
            yield
          end
        end

        # @return [String, nil] Resource ID for basis of request
        attr_reader :basis
        # @return [String, nil] Resource ID for project of request
        attr_reader :project
        # @return [String, nil] Resource ID for machine of request
        attr_reader :machine
        # @return [String, nil] GRPC endpoint for the Vagrant service
        attr_reader :vagrant_service_endpoint
        # @return [String] Name of requested plugin
        attr_reader :plugin_name

        CLIENT_LOCK = Mutex.new

        def initialize(basis: nil, project: nil, machine: nil, vagrant_service_endpoint: nil, plugin_name: nil)
          @basis = basis
          @project = project
          @machine = machine
          @vagrant_service_endpoint = vagrant_service_endpoint
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

        def self.client_for(service)
          CLIENT_LOCK.synchronize do
            @clients ||= {}
            return @clients[service] if @clients[service]
            @clients[service] = service::Stub.new(
              info.vagrant_service_endpoint,
              :this_channel_is_insecure,
              interceptors: [ClientInterceptor.new]
            )
          end
        end

        def self.with_info(context)
          info = new(
            basis: context.metadata["basis_resource_id"],
            project: context.metadata["project_resource_id"],
            machine: context.metadata["machine_resource_id"],
            vagrant_service_endpoint: context.metadata["vagrant_service_endpoint"],
            plugin_name: context.metadata["plugin_name"],
          )
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
