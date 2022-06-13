module VagrantPlugins
  module CommandServe
    module Service
      class ConfigService < ProtoService(SDK::ConfigService::Service)

        CONFIG_LOCATIONS = [
          :config,
          :provider_configs,
          :provisioner_configs,
          :push_configs,
        ]

        def register(req, ctx)
          with_plugin(ctx, CONFIG_LOCATIONS, broker: broker) do |plugin|
            resp = SDK::Config::RegisterResponse.new
            Vagrant.plugin("2").local_manager.registered.each do |plg|
              plg.components.configs.each do |scope, registry|
                registry.each do |ident, val|
                  if plugin == val
                    resp.scope = scope unless scope == :top
                    resp.identifier = ident
                    break
                  end
                end
              end
            end
            resp
          end
        end

        def merge_spec(*_)
          logger.debug("generating merge spec")
          funcspec(
            named: {
              base: SDK::Args::ConfigData,
              tomerge: SDK::Args::ConfigData,
            },
            result: SDK::Args::ConfigData,
          )
        end

        def merge(req, ctx)
          with_plugin(ctx, :config, broker: broker) do |plugin|
            base_raw = req.args.detect { |a| a.name == "base" }
            to_merge_raw = req.args.detect { |a| a.name == "tomerge" }
            if base_raw.nil? || to_merge_raw.nil?
              raise ArgumentError,
                    "Missing configuration value for merge"
            end

            base = mapper.unfuncspec(base_raw).to_ruby
            to_merge = mapper.unfuncspec(to_merge_raw).to_ruby

            result = base.merge(to_merge)
            result.to_proto
          end
        end

        def finalize_spec(*_)
          funcspec(
            args: [
              SDK::Args::ConfigData,
            ],
            result: SDK::Config::FinalizeResponse
          )
        end

        def finalize(req, ctx)
          with_plugin(ctx, CONFIG_LOCATIONS, broker: broker) do |plugin|
            logger.debug("finalizing configuration for plugin #{plugin}")
            config = mapper.unfuncspec(req.args.first).to_ruby

            if !config.is_a?(plugin)
              raise TypeError,
                    "Expected config type `#{plugin}' but received `#{config.class}'"
            end
            config.finalize!
            config.instance_variable_set("@__service_finalized", true)

            SDK::Config::FinalizeResponse.new(data: config.to_proto)
          end
        end
      end
    end
  end
end
