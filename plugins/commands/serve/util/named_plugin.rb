# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      module NamedPlugin
        module Service
          def set_plugin_name(req, ctx)
            # No opt
            Empty.new
          end
  
          def plugin_name(req, ctx)
            with_info(ctx, broker: broker) do |info|
              SDK::PluginInfo::Name.new(
                name: info.plugin_name
              )
            end
          end
        end

        module Client
          # @return [String] plugin name
          def name
            c = client.plugin_name(Empty.new)
            c.name
          end
        end
      end
    end
  end
end
