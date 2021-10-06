module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            # Vertex that represents an output of
            # a method
            class Output < Vertex
              attr_reader :type

              def initialize(type:)
                @type = type
              end

              # When an output Vertex is called,
              # we simply set the value for use
              def call(arg)
                @value = arg
              end

              def inspect
                "<Vertex:Output:#{object_id} hash=#{hash_code} type=#{type} value=#{value}>"
              end
            end
          end
        end
      end
    end
  end
end
