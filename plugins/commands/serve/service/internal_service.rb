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
        prepend Util::ExceptionLogger

        def get_plugins(req, _unused_call)
          plugins = []
          plugin_manager = Vagrant::Plugin::V2::Plugin.manager
          plugins = [[:commands, :COMMAND],
            [:communicators, :COMMUNICATOR],
            [:guests, :GUEST],
            [:hosts, :HOST],
            [:providers, :PROVIDER],
            [:provisioners, :PROVISIONER],
            [:synced_folders, :SYNCED_FOLDER]].map do |method, const|
            plugin_manager.send(method).map do |k, v|
              Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type.const_get(const))
            end
          end.flatten
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
            vm_config = root_config.vm
            provisioners = []
            vm_config.provisioners.each do |p|
              # On the other side of this, when the provisioner is getting read in 
              # by the (ruby) plugin, Vagrant must create a provisioner of this
              # type, with the map of options. That should look something like:
              #
              # plugin = Vagrant.plugin("2").manager.provisioners[p.type]
              # plugin_config = Vagrant.plugin("2").manager.provisioner_configs[p.type]
              # config = plugin_config.new
              # config.set_options(p.config)
              # provisioner = plugin.new(machine, config)
              # provisioner.provision
              
              config_struct = Google::Protobuf::Struct.from_hash(p.config.instance_variables_hash)
              config_any = Google::Protobuf::Any.pack(config_struct)
              provisioners << Hashicorp::Vagrant::VagrantfileComponents::Provisioner.new(
                name: p.name,
                type: p.type.to_s,
                before: p.before,
                after: p.after,
                communicator_required: p.communicator_required,
                config: config_any,
              )
            end
            machine_configs << Hashicorp::Vagrant::VagrantfileComponents::MachineConfig.new(
              name: mach.to_s,
              config_vm: Hashicorp::Vagrant::VagrantfileComponents::ConfigVM.new(
                box: vm_config.box,
                provisioners: provisioners,
              ),
            )
          end

          vagrantfile = Hashicorp::Vagrant::VagrantfileComponents::Vagrantfile.new(
            path: vagrantfile_path,
            raw: raw,
            current_version: Vagrant::Config::CURRENT_VERSION,
            machine_configs: machine_configs,
          )
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            vagrantfile: vagrantfile
          )
        end
      end
    end
  end
end
