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
        def get_plugins(req, _)
          plugins = []
          plugin_manager = Vagrant::Plugin::V2::Plugin.local_manager
          plugins = [[:commands, :COMMAND],
            [:communicators, :COMMUNICATOR],
            [:config, :CONFIG],
            [:guests, :GUEST],
            [:hosts, :HOST],
            [:provider_configs, :CONFIG],
            [:providers, :PROVIDER],
            [:provisioner_configs, :CONFIG],
            [:provisioners, :PROVISIONER],
            [:push_configs, :CONFIG],
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

        def parse_vagrantfile(req, _)
          path = req.path

          # Load up/parse the vagrantfile
          config_loader = loader
          config_loader.set(:root, path.to_s)
          config = config_loader.partial_load(:root)
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            data: config.to_proto,
          )
        end

        def parse_vagrantfile_proc(req, _)
          callable = mapper.map(req.proc, to: Proc)

          config_loader = loader
          config_loader.set(:root, [[2, callable]])
          config = config_loader.partial_load(:root)
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            data: config.to_proto,
          )
        end

        def parse_vagrantfile_subvm(req, _)
          subvm = mapper.map(req.subvm)

          config_loader = loader
          config_loader.set(:root, subvm.config_procs)
          config = config_loader.partial_load(:root)
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            data: config.to_proto,
          )
        end

        def loader
          Vagrant::Config::Loader.new(
            Vagrant::Config::VERSIONS,
            Vagrant::Config::VERSIONS_ORDER
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
