module VagrantPlugins
  module CommandServe
    module Util
      # Adds service info helper to be used with services
      module ServiceInfo
        def with_info(context)
          if !context.metadata["plugin_name"]
            raise KeyError,
              "plugin name not defined: #{context.metadata.inspect}"
          end
          info = Service::ServiceInfo.new(plugin_name: context.metadata['plugin_name'])
          Thread.current.thread_variable_set(:service_info, info)
          return if !block_given?
          begin
            yield info
          rescue => e
            raise "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          ensure
            Thread.current.thread_variable_set(:service_info, nil)
          end
        end
      end
    end
  end
end
