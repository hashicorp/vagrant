require "vagrant/plugin/v2/plugin"

require 'proto/gen/ruby-server_pb'
require 'proto/gen/ruby-server_services_pb'

module VagrantPlugins
  module CommandServe
    module Serve
      class PluginService < Hashicorp::Vagrant::RubyVagrant::Service
        def get_plugins(req, _unused_call)
          plugins = []
          plugin_manager = Vagrant::Plugin::V2::Plugin.manager
          plugin_manager.commands.each do |k, v| 
            plugins << Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type::COMMAND )
          end
          plugin_manager.communicators.each do |k, v| 
            plugins << Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type::COMMUNICATOR )
          end
          plugin_manager.guests.each do |k, v| 
            plugins << Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type::GUEST )
          end
          plugin_manager.hosts.each do |k, v| 
            plugins << Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type::HOST )
          end
          plugin_manager.providers.each do |k, v| 
            plugins << Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type::PROVIDER )
          end
          plugin_manager.provisioners.each do |k, v| 
            plugins << Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type::PROVISIONER )
          end
          plugin_manager.synced_folders.each do |k, v| 
            plugins << Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type::SYNCED_FOLDER )
          end
          Hashicorp::Vagrant::GetPluginsResponse.new(
            plugins: plugins
          )
        end
      end
    end
  end
end
