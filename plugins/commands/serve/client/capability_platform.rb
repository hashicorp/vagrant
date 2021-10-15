require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      module CapabilityPlatform

        def seed(*args)
          raise NotImplementedError,
            "Seeding is not currently supported via Ruby client"
        end

        def seeds
          res = client.seeds(Empty.new)
          res.list
        end

        # @param [Symbol] cap_name Capability name
        # @return [Boolean]
        def has_capability?(cap_name)
          logger.debug("checking for capability #{cap_name}")
          val = SDK::Args::NamedCapability.new(capability: cap_name.to_s)
          req = SDK::FuncSpec::Args.new(
            args: [SDK::FuncSpec::Value.new(
                name: "",
                type: "hashicorp.vagrant.sdk.Args.NamedCapability",
                value: Google::Protobuf::Any.pack(val)
            )]
          )

          res = client.has_capability(req)
          logger.debug("got result #{res}")

          res.has_capability
        end

        # @param [Symbol] cap_name Name of the capability
        def capability(cap_name, *args)
          logger.debug("executing capability #{cap_name}")
          arg_protos = seeds.map do |any|
            SDK::FuncSpec::Value.new(
              name: "",
              type: any.type_name,
              value: any,
            )
          end
          any_args = args.map do |a|
            if a.class.ancestors.include?(Google::Protobuf::MessageExts)
              val = a
            else
              val = Google::Protobuf::Value.new
              val.from_ruby(a)
            end
            Google::Protobuf::Any.pack(val)
          end

          arg_protos << SDK::FuncSpec::Value.new(
            name: "",
            type: "hashicorp.vagrant.sdk.Args.Direct",
            value: Google::Protobuf::Any.pack(SDK::Args::Direct.new(list: any_args)),
          )

          req = SDK::Platform::Capability::NamedRequest.new(
            name: cap_name.to_s,
            func_args: SDK::FuncSpec::Args.new(
              args: arg_protos,
            )
          )
          client.capability(req)
        end
      end
    end
  end
end
