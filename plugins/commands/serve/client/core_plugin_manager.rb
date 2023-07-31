# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class CorePluginManager < Client
        def get_plugin(type)
          resp = client.get_plugin(
            SDK::CorePluginManager::GetPluginRequest.new(
              type: type
            )
          )
          mapper.map(resp.plugin, broker)
        end
      end
    end
  end
end
