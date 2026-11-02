# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Service
      class ProvisionerService < ProtoService(SDK::ProvisionerService::Service)

        def cleanup(req, ctx)
          with_plugin(ctx, :provisioners, broker: broker) do |plugin|
            machine, plugin_config = _process_args(req)
            provisioner = load_provisioner(plugin, machine, plugin_config)
            provisioner.cleanup

            Empty.new
          end
        end

        def cleanup_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::ConfigData,
            ]
          )
        end

        def configure(req, ctx)
          with_plugin(ctx, :provisioners, broker: broker) do |plugin|
            machine, plugin_config = _process_args(req)
            provisioner = load_provisioner(plugin, machine, plugin_config)
            provisioner.configure(machine.config)

            Empty.new
          end
        end

        def configure_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::ConfigData,
            ]
          )
        end

        def provision(req, ctx)
          with_plugin(ctx, :provisioners, broker: broker) do |plugin|
            machine, plugin_config = _process_args(req)
            provisioner = load_provisioner(plugin, machine, plugin_config)
            provisioner.provision

            Empty.new
          end
        end

        def provision_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::ConfigData,
            ]
          )
        end

        # All of the methods here take the same args, so they have the same
        # args processing which can be shared
        #
        # @param req the request
        # @return [Array(Vagrant::Machine, Vagrant::Plugin::V2::Config)]
        def _process_args(req)
          machine, config = mapper.funcspec_map(
            req, mapper, broker, expect: [
              Vagrant::Machine, Vagrant::Plugin::V2::Config
            ]
          )
          return machine, config
        end

        def load_provisioner(klass, machine, config)
          ident = config.instance_variable_get(:@_vagrant_config_identifier)
          if ident
            key = cache.key(klass, machine, ident)
            return cache.get(key) if cache.registered?(key)
          end
          klass.new(machine, config).tap do |i|
            cache.register(key, i) if key
          end
        end
      end
    end
  end
end
