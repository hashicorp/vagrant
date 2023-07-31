# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      module HasSeeds
        # Provides seed value registration.
        module Service
          def seed(req, ctx)
            @seeds = req
            Empty.new
          end

          def seeds(req, ctx)
            return SDK::Args::Seeds.new if @seeds.nil?
            @seeds
          end
        end

        # Provides seed access.
        module Client
          def seed(*args)
            raise NotImplementedError,
              "Seeding is currently not supported via Ruby client"
          end

          def seeds
            client.seeds(Empty.new)
          end

          def seed_protos
            seeds.typed.map { |any|
              SDK::FuncSpec::Value.new(
                name: "",
                type: any.type_name,
                value: any,
              )
            } + seeds.named.map { |name, any|
              SDK::FuncSpec::Value.new(
                name: name,
                type: any.type_name,
                value: any,
              )
            }
          end
        end
      end
    end
  end
end
