
require_relative 'proto/gen/plugin/plugin_pb'
require_relative 'proto/gen/plugin/plugin_services_pb'

module VagrantPlugins
  module CommandServe
    module Serve
      class ProviderService < Hashicorp::Vagrant::Sdk::ProviderService::Service
        def usable(req, _unused_call)
          nil
        end

        def usable_spec(req, _unused_call)
          nil
        end

        def installed(req, _unused_call)
          nil
        end

        def installed_spec(req, _unused_call)
          nil
        end

        def init(req, _unused_call)
          nil
        end

        def init_spec(req, _unused_call)
          nil
        end

        def action_up(req, _unused_call)
          nil
        end

        def action_up_spec(req, _unused_call)
          nil
        end
      end
    end
  end
end
