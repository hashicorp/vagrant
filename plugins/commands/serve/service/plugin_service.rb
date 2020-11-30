require_relative 'proto/gen/ruby-server_pb'
require_relative 'proto/gen/ruby-server_services_pb'

module VagrantPlugins
  module CommandServe
    module Serve
      class PluginService < Hashicorp::Vagrant::RubyVagrant::Service
        def get_plugins(req, _unused_call)
          
          plugins = [Hashicorp::Vagrant::Plugin.new(name: "test")]
          Hashicorp::Vagrant::GetPluginsResponse.new(
            plugins: plugins
          )
        end
      end
    end
  end
end
