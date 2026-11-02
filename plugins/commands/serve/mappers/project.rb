# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class ProjectProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Project" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Project,
            func: method(:converter),
          )
        end

        def converter(fv)
          SDK::Args::Project.decode(fv.value.value)
        end
      end

      # Build a project client from a FuncSpec value
      class ProjectFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Args.Project" &&
                !arg&.value&.value.nil?
            }
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Project, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Project.load(proto.value.value, broker: broker)
        end
      end

      # Build a project client from a proto instance
      class ProjectFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Project)
            i << Input.new(type: Broker)
            i << Input.new(type: Util::Cacher)
          end
          super(inputs: inputs, output: Client::Project, func: method(:converter))
        end

        def converter(proto, broker, cacher)
          cid = proto.addr.to_s if proto.addr.to_s != ""
          return cacher.get(cid) if cid && cacher.registered?(cid)

          project = Client::Project.load(proto, broker: broker)
          cacher.register(cid, project) if cid
          project
        end
      end

      class ProjectFromTarget < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Client::Target)
          end
          super(inputs: inputs, output: Client::Project, func: method(:converter))
        end

        def converter(target)
          target.project
        end
      end
    end
  end
end
