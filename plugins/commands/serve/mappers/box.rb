module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a box client from a proto instance
      class BoxFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Box)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Box, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Box.load(proto, broker: broker)
        end
      end
    end
  end
end
