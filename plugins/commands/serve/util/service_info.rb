# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
            raise "Broker is required but was not provided"
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
              core_client = nil
              if context.metadata["core_plugin_manager"]
                core_client = Client::CorePluginManager.load(
                  context.metadata["core_plugin_manager"],
                  broker: info.broker
                )
              end
              Vagrant.plugin("2").enable_remote_manager(client, core_client: core_client)
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
            list = Array(plugins).inject({}) do |memo, key|
              memo.merge(Vagrant.plugin("2").local_manager.send(key))
            end
            plugin = Array(list[info.plugin_name]).first
            if !plugin
              raise NameError, "Failed to locate plugin '#{info.plugin_name}' within #{plugins} plugins"
            end
            yield plugin, info if block_given?
          end
        end
      end
    end
  end
end
