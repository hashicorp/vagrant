# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Service
      class SyncedFolderService < ProtoService(SDK::SyncedFolderService::Service)

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          super
          caps = Vagrant.plugin("2").local_manager.synced_folder_capabilities
          default_args = {
            Vagrant::Machine => SDK::Args::Target::Machine
          }
          initialize_capability_platform!(caps, default_args)
        end

        def usable_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
            ],
            result: SDK::SyncedFolder::UsableResp
          )
        end

        def usable(req, ctx)
          with_plugin(ctx, :synced_folders, broker: broker) do |plugin|
            machine = mapper.funcspec_map(
              req, expect: [Vagrant::Machine]
            )
            sf = load_synced_folder(plugin)
            usable = sf.usable?(machine)
            SDK::SyncedFolder::UsableResp.new(
              usable: usable,
            )
          end
        end


        def prepare_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::Folders,
              SDK::Args::Options,
            ]
          )
        end

        def prepare(req, ctx)
          with_plugin(ctx, :synced_folders, broker: broker) do |plugin|
            machine, folders, opts = mapper.funcspec_map(
              req,
              expect: [Vagrant::Machine, Type::Folders, Type::Options]
            )
            # change the top level folders hash key to a string
            folders = folders.value
            folders.transform_keys!(&:to_s)
            sf = load_synced_folder(plugin)
            sf.prepare(machine, folders, opts.value)
            Empty.new
          end
        end

        def enable_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::Folders,
              SDK::Args::Options,
            ]
          )
        end

        def enable(req, ctx)
          with_plugin(ctx, :synced_folders, broker: broker) do |plugin|
            machine, folders, opts = mapper.funcspec_map(
              req,
              expect: [Vagrant::Machine, Type::Folders, Type::Options]
            )
            # change the top level folders hash key to a string
            folders = folders.value
            folders.transform_keys!(&:to_s)
            sf = load_synced_folder(plugin)
            sf.enable(machine, folders, opts.value)
            Empty.new
          end
        end

        def disable_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::Folders,
              SDK::Args::Direct,
            ]
          )
        end

        def disable(req, ctx)
          with_plugin(ctx, :synced_folders, broker: broker) do |plugin|
            machine, folders, opts = mapper.funcspec_map(
              req,
              expect: [Vagrant::Machine, Type::Folders, Type::Options]
            )
            # change the top level folders hash key to a string
            folders = folders.value
            folders.transform_keys!(&:to_s)
            sf = load_synced_folder(plugin)
            sf.disable(machine, folders, opts.value)
            Empty.new
          end
        end

        def cleanup_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::Options,
            ]
          )
        end

        def cleanup(req, ctx)
          with_plugin(ctx, :synced_folders, broker: broker) do |plugin|
            machine, opts = mapper.funcspec_map(
              req,
              expect: [Vagrant::Machine, Type::Options]
            )

            sf = load_synced_folder(plugin)
            sf.cleanup(machine, opts.value)
            Empty.new
          end
        end

        def load_synced_folder(klass)
          key = cache.key(klass)
          return cache.get(key) if cache.registered?(key)
          klass.new.tap do |i|
            cache.register(key, i)
          end
        end
      end
    end
  end
end
