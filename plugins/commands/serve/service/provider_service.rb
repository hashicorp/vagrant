module VagrantPlugins
  module CommandServe
    module Service
      class ProviderService < SDK::ProviderService::Service

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          caps = Vagrant.plugin("2").local_manager.provider_capabilities
          default_args = {
            Client::Target::Machine => SDK::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Target.Machine",
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
            name: "action_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Options",
                name: "",
              )
            ],
            result: []
          )
        end

        def action(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.providers
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            action_name = req.name.to_sym
            machine, options = mapper.funcspec_map(
              req.func_args,
              expect: [Vagrant::Machine, Type::Options]
            )
            options = Type::Options.new(value: {}) if options.nil?

            provider = plugin.new(machine)

            # Within Ruby, many actions are defined inside provider plugins,
            # and within their implementations they assume that
            # `machine.provider` yields an instance of their provider. A common
            # instance of this assumption would be a call like
            # `machine.provider.driver.some_implementation_specific_method`.
            #
            # Because these assumptions are rampant within the Ruby
            # implementations of providers, we break encapsulation here to set
            # the local copy of the provider plugin on the machine.
            machine.instance_variable_set(:@provider, provider)

            callable = provider.action(action_name)
            if callable.nil?
              raise Errors::UnimplementedProviderAction,
              action: name,
              provider: @provider.to_s
            end
            action_raw(machine, action_name, callable, options.value)
            Empty.new
          end
        end

        def machine_id_changed_spec(*_)
          SDK::FuncSpec.new(
            name: "machine_id_changed_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              )
            ],
            result: [],
          )
        end

        def machine_id_changed(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.providers
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            machine = mapper.funcspec_map(req, expect: [Vagrant::Machine])
            provider = plugin.new(machine)
            provider.machine_id_changed
          end
          Empty.new
        end

        def ssh_info_spec(*_)
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
                type: "hashicorp.vagrant.sdk.Args.Connection.SSHInfo",
                name: "",
              ),
            ],
          )
        end

        def ssh_info(req, ctx)
          plugins = Vagrant.plugin("2").local_manager.providers
          with_plugin(ctx, plugins, broker: broker) do |plugin|
            machine = mapper.funcspec_map(req, expect: [Vagrant::Machine])
            provider = plugin.new(machine)
            info = provider.ssh_info
            info[:port] = info[:port].to_s if info.key?(:port)
            return SDK::Args::Connection::SSHInfo.new(**info)
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

        def action_raw(machine, name, callable, extra_env={})
          if !extra_env.is_a?(Hash)
            extra_env = {}
          end
          # Run the action with the action runner on the environment
          env = {ui: machine.ui}.merge(extra_env).merge(
            raw_action_name: name,
            action_name: "machine_action_#{name}".to_sym,
            machine: machine,
            machine_action: name
          )
          machine.env.action_runner.run(callable, env)
        end
      end
    end
  end
end
