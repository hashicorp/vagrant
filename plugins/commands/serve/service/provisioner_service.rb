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
              SDK::Vagrantfile::GeneralConfig,
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
              SDK::Vagrantfile::GeneralConfig,
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
              SDK::Vagrantfile::GeneralConfig,
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
              Vagrant::Machine, SDK::Vagrantfile::GeneralConfig
            ]
          )
          config_klass = config.type.split('::').inject(Kernel) { |memo, obj|
            memo.const_get(obj)
          }
          config_data = mapper.map(config.config, to: Hash)
          plugin_config = config_klass.new
          plugin_config.set_options(config_data)
          return machine, plugin_config
        end

        def load_provisioner(klass, machine, config)
          key = cache.key(klass, machine)
          return cache.get(key) if cache.registered?(key)
          klass.new(machine, config).tap do |i|
            cache.register(key, i)
          end
        end
      end
    end
  end
end
