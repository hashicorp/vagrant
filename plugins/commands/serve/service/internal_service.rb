# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
          globalized_plugins = Vagrant::Plugin::Manager.instance.globalize!
          Vagrant::Plugin::Manager.instance.load_plugins(globalized_plugins)
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

        def stop(_, _)
          if !VagrantPlugins::CommandServe.server.nil?
            logger.info("stopping the Vagrant Ruby runtime service")
            # We want to hop into a separate thread and pause for a moment
            # so we can send our response, then stop the server.
            Thread.new do
              sleep(0.05)
              VagrantPlugins::CommandServe.server.stop
            end
          else
            logger.warn("cannot stop Vagrant Ruby runtime service, not running")
          end
          Empty.new
        end

        def parse_vagrantfile(req, _)
          parse_item_to_proto(req.path.to_s)
        end

        def parse_vagrantfile_proc(req, _)
          callable = mapper.map(req.proc, to: Proc)

          parse_item_to_proto([["2", callable]])
        end

        def parse_vagrantfile_subvm(req, _)
          subvm = mapper.map(req.subvm)
          # If the subvm has no custom configuration, just return an empty result
          if subvm.config_procs.empty?
            return Hashicorp::Vagrant::ParseVagrantfileResponse.new(
              data: SDK::Args::Hash.new(entries: [])
            )
          end

          parse_item_to_proto(subvm.config_procs)
        end

        def parse_vagrantfile_provider(req, _)
          subvm = mapper.map(req.subvm)
          provider = req.provider.to_sym

          # If the subvm has no custom configuration, just return an empty result
          if subvm.config_procs.empty?
            return Hashicorp::Vagrant::ParseVagrantfileResponse.new(
              data: SDK::Args::Hash.new(entries: [])
            )
          end

          config = parse_item(subvm.config_procs)
          overrides = config.vm.get_provider_overrides(provider)

          # If the overrides are empty then no overrides were provided, just return
          # an empty result
          if overrides.empty?
            return Hashicorp::Vagrant::ParseVagrantfileResponse.new(
              data: SDK::Args::Hash.new(entries: [])
            )
          end

          parse_item_to_proto(overrides)
        end

        def parse_item(item)
          loader = Vagrant::Config::Loader.new(
            Vagrant::Config::VERSIONS,
            Vagrant::Config::VERSIONS_ORDER
          )
          loader.set(:item, item)
          loader.partial_load(:item)
        end

        def parse_item_to_proto(item)
          config = parse_item(item)
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            data: config.to_proto,
          )
        end

        def _convert_options_to_proto(type, class_or_tuple_with_class_and_options)
          case type
          when :COMMAND
            _, opts = class_or_tuple_with_class_and_options
            return SDK::PluginInfo::CommandOptions.new(
              # Primary is always set in V2::Plugin.command
              primary: opts[:primary],
            )
          when :COMMUNICATOR
            # No options for communicators
            return Google::Protobuf::Empty.new
          when :CONFIG
            # No options for configs
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
              # Parallel is defaults to falsy when its passed along as an arg to Environment#batch.
              parallel:     popts.fetch(:parallel, false),
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
