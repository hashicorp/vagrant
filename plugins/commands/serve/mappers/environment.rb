# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      class EnvironmentFromProject < Mapper
        include Util::HasLogger

        def initialize
          inputs = [
            Input.new(type: Client::Project),
            Input.new(type: Vagrant::UI::Remote),
            Input.new(type: Util::Cacher)
          ]
          super(inputs: inputs, output: Vagrant::Environment, func: method(:converter))
        end

        def converter(project, ui, cacher)
          cid = project.resource_id
          return cacher.get(cid) if cacher.registered?(cid)
          logger.warn { "cache miss for environment with project resource id #{cid} cache=#{cacher} !!" }
          env = Vagrant::Environment.new(ui: ui, client: project)
          cacher.register(cid, env)
          env
        end
      end

      class EnvironmentToProject < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Vagrant::Environment)],
            output: Client::Project,
            func: method(:converter),
          )
        end

        def converter(env)
          env.client
        end
      end

      class EnvironmentToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Vagrant::Environment)],
            output: SDK::Args::Project,
            func: method(:converter),
          )
        end

        def converter(env)
          env.client.to_proto
        end
      end

      class EnvironmentFromProjectNoUI < Mapper
        include Util::HasLogger

        def initialize
          inputs = [
            Input.new(type: Client::Project),
            Input.new(type: Util::Cacher),
            Input.new(type: Mappers)
          ]
          super(inputs: inputs, output: Vagrant::Environment, func: method(:converter))
        end

        def converter(project, cacher, mapper)
          cid = project.resource_id
          return cacher.get(cid) if cacher.registered?(cid)
          logger.warn { "cache miss for environment with project resource id #{cid} cache=#{cacher}" }
          ui = mapper.map(project, to: Vagrant::UI::Remote)
          env = Vagrant::Environment.new(client: project, ui: ui)
          cacher.register(cid, env)
          env
        end
      end
    end
  end
end
