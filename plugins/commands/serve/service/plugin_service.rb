require "vagrant/plugin/manager"

require_relative 'proto/gen/ruby-server_pb'
require_relative 'proto/gen/ruby-server_services_pb'

module VagrantPlugins
  module CommandServe
    module Serve
      class PluginService < Hashicorp::Vagrant::RubyVagrant::Service
        def get_plugins(req, _unused_call)
          installed_plugins = Vagrant::Plugin::Manager.instance.installed_plugins
          ruby_plugins = installed_plugins.map { |k, v| Hashicorp::Vagrant::Plugin.new(name: k) }
          Hashicorp::Vagrant::GetPluginsResponse.new(
            plugins: ruby_plugins
          )
        end
      end
    end
  end
end
