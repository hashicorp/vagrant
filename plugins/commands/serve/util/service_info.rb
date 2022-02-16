module VagrantPlugins
  module CommandServe
    module Util
      # Adds service info helper to be used with services
      module ServiceInfo
        def with_info(context, broker:, &block)
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
          return if !block_given?
          yield info
        ensure
          if activated
            Service::ServiceInfo.manager_tracker.deactivate do
              Vagrant.plugin("2").disable_remote_manager
            end
          end
          Thread.current.thread_variable_set(:service_info, nil)
        end

        def with_plugin(context, plugins, broker:, &block)
          with_info(context, broker: broker) do |info|
            plugin_name = info.plugin_name
            plugin = Array(plugins[plugin_name.to_s.to_sym]).first
            if !plugin
              raise NameError, "Failed to locate plugin named #{plugin_name}"
            end
            yield plugin if block_given?
          end
        end
      end
    end
  end
end
