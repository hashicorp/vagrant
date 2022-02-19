module VagrantPlugins
  module CommandServe
    module Util
      # Adds service info helper to be used with services
      module ServiceInfo
        # Call block and yield information about
        # the incoming request based on provided
        # context.
        #
        # @param context [GRPC::Context] Request context
        # @param broker [Broker]
        # @yieldparam [ServiceInfo]
        def with_info(context, broker:, &block)
          if broker.nil?
            raise "NO BROKER FOR INFO"
          end
          if !context.metadata["plugin_name"]
            raise KeyError,
              "plugin name not defined (metadata content: #{context.metadata.inspect})"
          end

          info = Service::ServiceInfo.new(
            plugin_name: context.metadata["plugin_name"],
            broker: broker
          )
          if context.metadata["plugin_manager"] && info.broker
            activated = true
            Service::ServiceInfo.manager_tracker.activate do
              client = Client::PluginManager.load(
                context.metadata["plugin_manager"],
                broker: info.broker
              )
              Vagrant.plugin("2").enable_remote_manager(client)
            end
          end
          Thread.current.thread_variable_set(:service_info, info)
          yield info if block_given?
        ensure
          if activated
            Service::ServiceInfo.manager_tracker.deactivate do
              Vagrant.plugin("2").disable_remote_manager
            end
          end
          Thread.current.thread_variable_set(:service_info, nil)
        end

        # Call given block and yield local plugin class
        # and information about the incoming request based
        # on provided context.
        #
        # @param context [GRPC::Context] Request context
        # @param plugins [Symbol] Type of plugins (:providers, :provisioners, etc.)
        # @param broker [Broker]
        def with_plugin(context, plugins, broker:, &block)
          with_info(context, broker: broker) do |info|
            plugin = Array(
              Vagrant.plugin("2").
                local_manager.
                send(plugins)[info.plugin_name]
            ).first
            if !plugin
              raise NameError, "Failed to locate plugin '#{plugin_name}' within #{plugins} plugins"
            end
            yield plugin, info if block_given?
          end
        end
      end
    end
  end
end
