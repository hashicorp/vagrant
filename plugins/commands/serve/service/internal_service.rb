require "vagrant/plugin/v2/plugin"
require "vagrant/vagrantfile"
require "vagrant/box_collection"
require "vagrant/config"
require "pathname"

require 'google/protobuf/well_known_types'

module VagrantPlugins
  module CommandServe
    module Service
      class InternalService < Hashicorp::Vagrant::RubyVagrant::Service
        prepend Util::HasBroker
        prepend Util::HasLogger
        include Util::ExceptionTransformer

        def get_plugins(req, _unused_call)
          plugins = []
          plugin_manager = Vagrant::Plugin::V2::Plugin.local_manager
          plugins = [[:commands, :COMMAND],
            [:communicators, :COMMUNICATOR],
            [:guests, :GUEST],
            [:hosts, :HOST],
            [:providers, :PROVIDER],
            [:provisioners, :PROVISIONER],
            [:pushes, :PUSH],
            [:synced_folders, :SYNCEDFOLDER]].map do |method, const|
            plugin_manager.send(method).map do |k, v|
              Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type.const_get(const))
            end
          end.flatten
          Hashicorp::Vagrant::GetPluginsResponse.new(
            plugins: plugins
          )
        end

        def parse_vagrantfile(req, _unused_call)
          path = req.path
          raw = File.read(path)

          # Load up/parse the vagrantfile
          config_loader = Vagrant::Config::Loader.new(
            Vagrant::Config::VERSIONS, Vagrant::Config::VERSIONS_ORDER)
          config_loader.set(:root, path)
          v = Vagrant::Vagrantfile.new(config_loader, [:root])

          machine_configs = []
          # Get the config for each machine
          v.machine_names.each do |mach|
            machine_info = v.machine_config(mach, nil, nil, false)
            root_config = machine_info[:config]
            vm_config = root_config.vm

            plugin_configs = []
            root_config.__internal_state["keys"].each do |name, config|
              # A builtin plugin
              # TODO: find a better way to check the module
              next if config.class.to_s.split("::")[0] == "VagrantPlugins"
              plugin_configs << config.to_proto(name)
            end
            plugin_configs << root_config.ssh.to_proto("ssh")
            plugin_configs << root_config.winrm.to_proto("winrm")
            plugin_configs << root_config.winssh.to_proto("winssh")

            machine_configs << Hashicorp::Vagrant::Sdk::Vagrantfile::MachineConfig.new(
              name: mach.to_s,
              config_vm: vm_config.to_proto,
              config_vagrant: root_config.vagrant.to_proto(),
              plugin_configs: plugin_configs
            )
          end

          push_configs = v.config.push.to_proto

          vagrantfile = Hashicorp::Vagrant::Sdk::Vagrantfile::Vagrantfile.new(
            path: path,
            raw: raw,
            current_version: Vagrant::Config::CURRENT_VERSION,
            machine_configs: machine_configs,
            push_configs: push_configs,
          )
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            vagrantfile: vagrantfile
          )
        end
      end
    end
  end
end
