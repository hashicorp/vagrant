# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require 'ostruct'

module VagrantPlugins
  module CommandServe
    class Client
      class Vagrantfile < Client
        def target_names
          resp = client.target_names(Empty.new)
          resp.names.map(&:to_sym)
        end

        def target(name, provider)
          key = "target/#{name}/#{provider}"
          logger.info("getting target #{key}")

          Target.load(
            client.target(
              SDK::Vagrantfile::TargetRequest.new(
                name: name,
                provider: provider,
              ),
            ),
            broker: broker
          )
        end

        def target_config(name, provider, validate_provider)
          result = client.target_config(
            SDK::Vagrantfile::TargetConfigRequest.new(
              name: name,
              provider: provider,
              validate_provider: validate_provider
            )
          )
          vf = mapper.map(result, to: Vagrant::Vagrantfile)
          OpenStruct.new(config: vf.config)
        end

        def machine_config(name, provider, validate_provider)
          key = "config/#{name}/#{provider}"
          logger.info("getting target config #{key}")

          target_config(name, provider, validate_provider)
        end

        def machine(name, provider)
          key = "machine/#{name}/#{provider}"
          logger.info("getting machine #{key}")

          Vagrant::Machine.new(client: target(name, provider).to_machine)
        end

        def get_config(namespace)
          logger.info("getting config for namespace: #{namespace}")
          result = client.get_config(
            SDK::Vagrantfile::NamespaceRequest.new(
              namespace: namespace
            )
          )

          result.to_ruby
        end

        def get_value(*path)
          logger.info("getting config value for path: #{path}")
          result = client.get_value(
            SDK::Vagrantfile::ValueRequest.new(
              path: path,
            )
          )

          val = result.to_ruby.arguments.first
          return val.value if val.is_a?(Type)

          val
        end
      end
    end
  end
end
