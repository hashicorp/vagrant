# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class BasisProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Basis" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Basis,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::Basis.decode(fv.value.value)
        end
      end

      # Build a basis client from a proto instance
      class BasisFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Basis)
            i << Input.new(type: Broker)
            i << Input.new(type: Util::Cacher)
          end
          super(inputs: inputs, output: Client::Basis, func: method(:converter))
        end

        def converter(proto, broker, cacher)
          cid = proto.addr.to_s if proto.addr.to_s != ""
          return cacher.get(cid) if cid && cacher.registered?(cid)

          project = Client::Basis.load(proto, broker: broker)
          cacher.register(cid, project) if cid
          project
        end
      end
    end
  end
end
