# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
              proto: plg.plugin,
              options: _plugin_options_to_hash(plg.options),
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

        # Plugin options are an Any that contains one of the types defined in
        # component.*Options in the SDK.
        #
        # On the Ruby side, plugin options are just a value that get stuffed in
        # a tuple next to the plugin in the manager. Its type is context
        # dependent so we need to unpack each kind of plugin options with its
        # own logic.
        def _plugin_options_to_hash(plg_opts)
          return {} if plg_opts.nil?
          opts = mapper.unany(plg_opts)
          case opts
          when Hashicorp::Vagrant::Sdk::PluginInfo::CommandOptions
            opts.to_h
          when Hashicorp::Vagrant::Sdk::PluginInfo::ProviderOptions
            opts.to_h
          when Hashicorp::Vagrant::Sdk::PluginInfo::SyncedFolderOptions
            opts.priority
          else
            raise ArgumentError, "unexpected plugin options #{opts.inspect}"
          end
        end
      end
    end
  end
end
