require "vagrant/plugin/v2/plugin"
require "vagrant/vagrantfile"
require "vagrant/box_collection"
require "vagrant/config"
require 'pp'
require "pathname"

require 'vagrant/proto/gen/ruby-server_pb'
require 'vagrant/proto/gen/ruby-server_services_pb'

module VagrantPlugins
  module CommandServe
    module Serve
      class RubyVagrantService < Hashicorp::Vagrant::RubyVagrant::Service
        LOG = Logger.new('/tmp/vagrant-ruby.txt')

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

        def parse_vagrantfile(req, _unused_call)
          vagrantfile_path = req.path
          raw = File.read(vagrantfile_path)

          # Load up/parse the vagrantfile
          config_loader = Vagrant::Config::Loader.new(
            Vagrant::Config::VERSIONS, Vagrant::Config::VERSIONS_ORDER)
          config_loader.set(:root, vagrantfile_path) 
          v = Vagrant::Vagrantfile.new(config_loader, [:root])

          machine_configs = []
          # Get the config for each machine
          v.machine_names.each do |mach|
            machine_info = v.machine_config(mach, nil, nil)
            root_config = machine_info[:config]
            config = root_config.vm
            machine_configs << Hashicorp::Vagrant::MachineConfig.new(
              name: mach.to_s,
              box: config.box,
              provisioner: []
            )
          end
          
          vagrantfile = Hashicorp::Vagrant::Vagrantfile.new(
            raw: raw,
            current_version: Vagrant::Config::CURRENT_VERSION,
            machine_config: machine_configs
          )
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            vagrantfile: vagrantfile
          )
        end
      end
    end
  end
end
