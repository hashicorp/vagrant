module VagrantPlugins
  module CommandServe
    module Service
      class ProviderService < SDK::ProviderService::Service
        
        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          caps = Vagrant.plugin("2").local_manager.provider_capabilities
          default_args = {
            Client::Target => SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target",
              name: "",
            ),
          }
          initialize_capability_platform!(caps, default_args)
        end

        def usable_spec(*_)
          SDK::FuncSpec.new(
            name: "usable_spec",
            args: [],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Provider.UsableResp",
                name: "",
              ),
            ],
          )
        end

        def usable(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.providers
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            is_usable = plugin.usable?
            SDK::Provider::UsableResp.new(
              is_usable: is_usable,
            )
          end
        end

        def installed_spec(*_)
          SDK::FuncSpec.new(
            name: "installed_spec",
            args: [],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Provider.InstalledResp",
                name: "",
              ),
            ],
          )
        end

        def installed(*_)
          plugins = Vagrant.plugin("2").local_manager.providers
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            is_installed = plugin.installed?
            SDK::Provider::InstalledResp.new(
              is_installed: is_installed,
            )
          end
        end

        def action_spec(req, _unused_call)
          SDK::FuncSpec.new(
            name: "capability_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Direct",
                name: "",
              )
            ],
            result: []
          )
        end

        def action_up(req, ctx)
          # TODO
          nil
        end

        def machine_id_changed_spec(*_)
          SDK::FuncSpec.new(
            name: "machine_id_changed_spec",
            args: [],
            result: [],
          )
        end

        def machine_id_changed(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.providers
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            provider = plugin.new
            # TODO: does this provider need to be initialized?
            # provider.initialize(machine)?
            provider.machine_id_changed
          end
          Empty.new
        end

        def ssh_info_spec(*_)
          SDK::FuncSpec.new(
            name: "ssh_info_spec",
            args: [],
            result: [
              SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.SSHInfo",
              name: "",
              ),
            ],
          )
        end

        def ssh_info(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.providers
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            provider = plugin.new
            # TODO: does this provider need to be initialized?
            # provider.initialize(machine)?
            info = provider.ssh_info
            return SDK::SSHInfo.new(
              host: info[:host],
              port: info[:port],
              username: info[:username],
              private_key_path: info[:private_key_path]
            )
          end
        end

        def state_spec(*_)
          SDK::FuncSpec.new(
            name: "ssh_info_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              )
            ],
            result: [
              SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target.Machine.State",
              name: "",
              ),
            ],
          )
        end

        def state(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.providers
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            machine = mapper.funcspec_map(req, expect: [Vagrant::Machine])
            provider = plugin.new(machine)
            machine_state = provider.state
            return mapper.map(machine_state, to: SDK::Args::Target::Machine::State)
          end
        end
      end
    end
  end
end
