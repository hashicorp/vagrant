# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
            args: [
              SDK::Config::Merge,
            ],
            result: SDK::Args::ConfigData,
          )
        end

        def merge(req, ctx)
          with_plugin(ctx, :config, broker: broker) do |plugin|
            m = mapper.unfuncspec(req.args.first)
            base = mapper.map(m.base, to: plugin)
            overlay = mapper.map(m.overlay, to: plugin)

            mapper.map(base.merge(overlay), to: SDK::Args::ConfigData)
          end
        end

        def finalize_spec(*_)
          funcspec(
            args: [
              SDK::Config::Finalize,
            ],
            result: SDK::Args::ConfigData
          )
        end

        def finalize(req, ctx)
          with_plugin(ctx, CONFIG_LOCATIONS, broker: broker) do |plugin|
            logger.debug("finalizing configuration for plugin #{plugin}")

            # Extract the proto from the funcspec
            f = mapper.unfuncspec(req.args.first)
            cproto = f.config

            # If the config data does not include a source class, we treat
            # the request as simply wanting the default finalized data
            if cproto.source.name.to_s.empty?
              config = plugin.new
            else
              config = mapper.map(cproto, to: plugin)
            end

            config.finalize!
            # This is just a marker for debugging that we were
            # responsible for the finalization
            config.instance_variable_set("@__service_finalized", true)

            mapper.map(config, to: SDK::Args::ConfigData)
          end
        end
      end
    end
  end
end
