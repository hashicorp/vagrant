require 'google/protobuf/well_known_types'

module VagrantPlugins
  module CommandServe
    module Service
      class SyncedFolderService < SDK::SyncedFolderService::Service

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          caps = Vagrant.plugin("2").local_manager.synced_folder_capabilities
          default_args = {
            Vagrant::Machine => SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target.Machine",
              name: "",
            ),
          }
          initialize_capability_platform!(caps, default_args)
        end

        def usable_spec(*_)
          SDK::FuncSpec.new(
            name: "usable_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              )
            ],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.SyncedFolder.UsableResp",
                name: "",
              ),
            ],
          )
        end

        def usable(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.synced_folders
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            target = mapper.funcspec_map(req)
            project = target.project
            env = Vagrant::Environment.new({client: project})
            machine = env.machine(target.name.to_sym, target.provider_name.to_sym)

            sf = plugin.new
              usable = sf.usable?(machine)
              logger.debug("usable: #{usable}")
              SDK::SyncedFolder::UsableResp.new(
                usable: usable,
              )
          end
        end


        def prepare_spec(*_)
          SDK::FuncSpec.new(
            name: "prepare_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Folders",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Options",
                name: "",
              ),
            ],
          )
        end

        def prepare(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.synced_folders
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            machine, folders, opts = mapper.funcspec_map(
              req,
              expect: [Vagrant::Machine, Type::Folders, Type::Options]
            )
            # change the top level folders hash key to a string
            folders = folders.value
            folders.transform_keys!(&:to_s)
            sf = plugin.new
            sf.prepare(machine, folders, opts.value)
            Empty.new
          end
        end

        def enable_spec(*_)
          SDK::FuncSpec.new(
            name: "enable_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Folders",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Options",
                name: "",
              ),
            ],
          )
        end

        def enable(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.synced_folders
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            machine, folders, opts = mapper.funcspec_map(
              req.func_args,
              expect: [Vagrant::Machine, Folders, Type::Options]
            )
            # change the top level folders hash key to a string
            folders = folders.value
            folders.transform_keys!(&:to_s)
            sf = plugin.new
            sf.enable(machine, folders, opts.value)
            Empty.new
          end
        end

        def disable_spec(*_)
          SDK::FuncSpec.new(
            name: "disable_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Folders",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Options",
                name: "",
              ),
            ],
          )
        end

        def disable(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.synced_folders
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            machine, folders, opts = mapper.funcspec_map(
              req.func_args,
              expect: [Vagrant::Machine, Type::Folders, Type::Options]
            )
            # change the top level folders hash key to a string
            folders = folders.value
            folders.transform_keys!(&:to_s)
            sf = plugin.new
            sf.disable(machine, folders, opts.value)
            Empty.new
          end
        end

        def cleanup_spec(*_)
          SDK::FuncSpec.new(
            name: "cleanup_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Options",
                name: "",
              ),
            ],
          )
        end

        def cleanup(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.synced_folders
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            machine, opts = mapper.funcspec_map(
              req.func_args,
              expect: [Vagrant::Machine, Type::Options]
            )

            sf = get_synced_folder_plugin(plugin_name)
            sf.cleanup(machine, opts.value)
            Empty.new
          end
        end
      end
    end
  end
end
