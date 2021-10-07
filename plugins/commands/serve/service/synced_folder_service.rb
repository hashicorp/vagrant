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
            # TODO
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
                type: "hashicorp.vagrant.sdk.Args.OptionsHash",
                name: "",
              ),
             #TODO
            ],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.SyncedFolder.UsableResp",
                name: "",
              ),
            ],
          )
        end

        def enable(req, ctx)
          with_info(ctx) do |info|
            # TODO
          end
        end


      end
    end
  end
end
