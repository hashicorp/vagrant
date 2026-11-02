# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class VagrantfileProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Vagrantfile" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Vagrantfile,
            func: method(:converter),
          )
        end

        def converter(f)
          SDK::Args::Vagrantfile.decode(fv.value.value)
        end
      end

      class VagrantfileFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::Vagrantfile),
              Input.new(type: Broker),
              Input.new(type: Util::Cacher),
            ],
            output: Client::Vagrantfile,
            func: method(:converter)
          )
        end

        def converter(proto, broker, cacher)
          cid = proto.addr.to_s if proto.addr.to_s != ""
          return cacher.get(cid) if cid && cacher.registered?(cid)

          v = Client::Vagrantfile.load(proto, broker: broker)
          cacher.register(cid, v) if cid
          v
        end
      end

      class VagrantfileFromClient < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Client::Vagrantfile),
            ],
            output: Vagrant::Vagrantfile,
            func: method(:converter),
          )
        end

        def converter(client)
          Vagrant::Vagrantfile.new(client: client)
        end
      end
    end
  end
end
