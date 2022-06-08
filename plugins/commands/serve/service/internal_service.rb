require "vagrant/plugin/v2/plugin"
require "vagrant/vagrantfile"
require "vagrant/box_collection"
require "vagrant/config"
require "pathname"

require 'google/protobuf/well_known_types'

module VagrantPlugins
  module CommandServe
    module Service
      class InternalService < ProtoService(Hashicorp::Vagrant::RubyVagrant::Service)
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
              Hashicorp::Vagrant::Plugin.new(
                name: k,
                type: Hashicorp::Vagrant::Plugin::Type.const_get(const),
                options: Google::Protobuf::Any.pack(
                  _convert_options_to_proto(const, v)
                )
              )
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

        def _convert_options_to_proto(type, class_or_tuple_with_class_and_options)
          case type
          when :COMMAND
            # _, command_options = class_or_tuple_with_class_and_options
            return Google::Protobuf::Empty.new
          when :COMMUNICATOR
            # No options for communicators
            return Google::Protobuf::Empty.new
          when :GUEST
            # No options for guests
            return Google::Protobuf::Empty.new
          when :HOST
            # _, parent = class_or_tuple_with_class_and_options
            return Google::Protobuf::Empty.new
          when :PROVIDER
            _, popts = class_or_tuple_with_class_and_options
            return SDK::PluginInfo::ProviderOptions.new(
              # Priority is always set in V2::Plugin.provider
              priority:     popts[:priority],
              # Parallel is passed along to Environment#batch which defaults it to true
              parallel:     popts.fetch(:parallel, true),
              # BoxOptional defaults to falsy when it's used in Kernel_V2::VMConfig
              box_optional: popts.fetch(:box_optional, false),
              # Defaultable is considered true when it is not specified in Environment#default_provider
              defaultable:  popts.fetch(:defaultable, true),
            )
          when :PROVISIONER
            # No options for provisioners
            return Google::Protobuf::Empty.new
          when :PUSH
            # Push plugins accept an options hash but it's never used.
            return Google::Protobuf::Empty.new
          when :SYNCEDFOLDER
            _, sf_priority = class_or_tuple_with_class_and_options
            return SDK::PluginInfo::SyncedFolderOptions.new(
              priority: sf_priority,
            )
          else
            raise "Cannot convert options for unknown component type: #{type}"
          end
        end
      end
    end
  end
end
