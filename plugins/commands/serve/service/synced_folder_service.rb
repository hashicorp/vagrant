require 'google/protobuf/well_known_types'

module VagrantPlugins
  module CommandServe
    module Service
      class SyncedFolderService < SDK::SyncedFolderService::Service

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          caps = Vagrant.plugin("2").manager.synced_folder_capabilities
          default_args = [
            # Always get a target to pass the synced folder capability
            SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target",
              name: "",
            ),
          ]
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
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            target = mapper.funcspec_map(req)
            project = target.project
            env = Vagrant::Environment.new({client: project})
            machine = env.machine(target.name.to_sym, target.provider_name.to_sym)
            
            sf = get_synced_folder_plugin(plugin_name)
            logger.debug("got sf #{sf}")
            usable = sf.usable?(machine)
            logger.debug("usable: #{usable}")
            SDK::SyncedFolder::UsableResp.new(
              usable: usable,
            )
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
                type: "hashicorp.vagrant.sdk.Args.Folder",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Direct",
                name: "",
              ),
            ],
          )
        end

        def enable(req, ctx)
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            machine, folders, opts = mapper.funcspec_map(
              req.func_args,
              expect: [Vagrant::Machine, Hash, Types::Direct]
            )

            sf = get_synced_folder_plugin(plugin_name)
            sf.enable(machine, folders, opts)
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
                type: "hashicorp.vagrant.sdk.Args.Folder",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Direct",
                name: "",
              ),
            ],
          )
        end

        def disable(req, ctx)
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            machine, folders, opts = mapper.funcspec_map(
              req.func_args,
              expect: [Vagrant::Machine, Hash, Types::Direct]
            )

            sf = get_synced_folder_plugin(plugin_name)
            sf.disable(machine, folders, opts)
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
                type: "hashicorp.vagrant.sdk.Args.Direct",
                name: "",
              ),
            ],
          )
        end

        def cleanup(req, ctx)
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            machine, opts = mapper.funcspec_map(
              req.func_args,
              expect: [Vagrant::Machine, Types::Direct]
            )

            sf = get_synced_folder_plugin(plugin_name)
            sf.cleanup(machine, opts)
            Empty.new
          end
        end

        private
        
        def get_synced_folder_plugin(plugin_name)
          synced_folders = Vagrant.plugin("2").manager.synced_folders
          logger.debug("got synced folders #{synced_folders}")
          plugin = [plugin_name.to_s.to_sym].to_a.first
          logger.debug("got plugin #{plugin}")
          sf = plugin.new
          logger.debug("got sf #{sf}")
          sf
        end
      end
    end
  end
end
