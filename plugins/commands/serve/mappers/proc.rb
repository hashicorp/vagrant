# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require "singleton"

module VagrantPlugins
  module CommandServe
    class Mappers
      class ProcRegistry
        include Singleton

        def initialize
          @m = Mutex.new
          @stored = {}
        end

        def register(value)
          @m.synchronize do
            if !value.is_a?(Proc)
              raise TypeError,
                "Expected type `Proc' but received `#{value.class}'"
            end

            # If this is already stored, return existing ID
            idx = @stored.key(value)
            return idx if idx

            # Create a new ID and store
            id = SecureRandom.uuid
            @stored[id] = value
            id
          end
        end

        def fetch(idx)
          @m.synchronize do
            if !@stored.key?(idx)
              raise KeyError,
                "No `Proc' registered for given ID (#{idx})"
            end
          end
          @stored[idx]
        end
      end

      class ProcToProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: Proc),
            ],
            output: SDK::Args::ProcRef,
            func: method(:converter),
          )
        end

        def converter(value)
          SDK::Args::ProcRef.new(
            id: ProcRegistry.instance.register(value),
          )
        end
      end

      class ProcFromProto < Mapper
        def initialize
          super(
            inputs: [
              Input.new(type: SDK::Args::ProcRef),
            ],
            output: Proc,
            func: method(:converter)
          )
        end

        def converter(proto)
          ProcRegistry.instance.fetch(proto.id)
        end
      end
    end
  end
end
