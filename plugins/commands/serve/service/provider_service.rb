# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Service
      class ProviderService < ProtoService(SDK::ProviderService::Service)

        include CapabilityPlatformService

        def initialize(*args, **opts, &block)
          super
          caps = Vagrant.plugin("2").local_manager.provider_capabilities
          default_args = {
            Vagrant::Machine => SDK::Args::Target::Machine
          }
          initialize_capability_platform!(caps, default_args)
        end

        def usable_spec(*_)
          funcspec(result: SDK::Provider::UsableResp)
        end

        def usable(req, ctx)
          with_plugin(ctx, :providers, broker: broker) do |plugin|
            is_usable = plugin.usable?(true)
            SDK::Provider::UsableResp.new(
              is_usable: is_usable,
            )
          end
        end

        def installed_spec(*_)
          funcspec(result: SDK::Provider::InstalledResp)
        end

        def installed(req, ctx)
          with_plugin(ctx, :providers, broker: broker) do |plugin|
            is_installed = plugin.installed?
            SDK::Provider::InstalledResp.new(
              is_installed: is_installed,
            )
          end
        end

        def action_spec(req, _unused_call)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::Options,
            ]
          )
        end

        def action(req, ctx)
          with_plugin(ctx, :providers, broker: broker) do |plugin|
            action_name = req.name.to_sym
            machine, options = mapper.funcspec_map(
              req.func_args,
              expect: [Vagrant::Machine, Type::Options]
            )
            options = Type::Options.new(value: {}) if options.nil?

            provider = load_provider(plugin, machine)

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
          funcspec(
            args: [
              SDK::Args::Target::Machine,
            ]
          )
        end

        def machine_id_changed(req, ctx)
          with_plugin(ctx, :providers, broker: broker) do |plugin|
            machine = mapper.funcspec_map(req, expect: [Vagrant::Machine])
            provider = load_provider(plugin, machine)
            provider.machine_id_changed
          end
          Empty.new
        end

        def ssh_info_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
            ],
            result: SDK::Args::Connection::SSHInfo
          )
        end

        def ssh_info(req, ctx)
          with_plugin(ctx, :providers, broker: broker) do |plugin|
            machine = mapper.funcspec_map(req, expect: [Vagrant::Machine])
            provider = load_provider(plugin, machine)
            info = provider.ssh_info
            info[:port] = info[:port].to_s if info.key?(:port)
            return SDK::Args::Connection::SSHInfo.new(**info)
          end
        end

        def state_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target
            ],
            result: SDK::Args::Target::Machine::State,
          )
        end

        def state(req, ctx)
          with_plugin(ctx, :providers, broker: broker) do |plugin|
            machine = mapper.funcspec_map(req, expect: [Vagrant::Machine])
            provider = load_provider(plugin, machine)
            machine_state = provider.state
            return mapper.map(machine_state, to: SDK::Args::Target::Machine::State)
          end
        end

        def action_raw(machine, name, callable, extra_env={})
          if !extra_env.is_a?(Hash)
            extra_env = {}
          end
          # Run the action with the action runner on the environment
          env = extra_env.merge(
            raw_action_name: name,
            action_name: "machine_action_#{name}".to_sym,
            machine: machine,
            machine_action: name,
            ui: machine.ui,
          )
          machine.env.action_runner.run(callable, env)
        end

        def capability_arguments(args)
          target, direct = args
          nargs = direct.args.dup
          if !nargs.first.is_a?(Vagrant::Machine)
            nargs.unshift(mapper.map(target, to: Vagrant::Machine))
          end

          nargs
        end

        def load_provider(klass, machine)
          key = cache.key(klass, machine)
          return cache.get(key) if cache.registered?(key)
          klass.new(machine).tap do |i|
            cache.register(key, i)
          end
        end
      end
    end
  end
end
