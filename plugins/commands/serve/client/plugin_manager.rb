module VagrantPlugins
  module CommandServe
    class Client
      class PluginManager < Client
        def list_plugins(types=[])
          resp = client.list_plugins(
            SDK::PluginManager::PluginsRequest.new(
              types: Array(types).map(&:to_s)
            )
          )
          resp.plugins.map do |plg|
            Vagrant::Util::HashWithIndifferentAccess.new(
              name: plg.name,
              type: plg.type,
              proto: plg.plugin
            )
          end
        end

        def get_plugin(name:, type:)
          logger.info("fetching plugin from vagrant-agogo name: #{name}, type: #{type}")
          resp = client.get_plugin(
            SDK::PluginManager::Plugin.new(
              name: name,
              type: type
            )
          )
          mapper.map(resp.plugin, broker)
        end
      end
    end
  end
end
