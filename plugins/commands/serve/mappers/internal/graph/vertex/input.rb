module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            # Vertex that represents an input value
            # for a method
            class Input < Vertex
              attr_reader :type

              def initialize(type:)
                @type = type
              end

              # When an input Vertex is called,
              # we simply set the value for use
              def call(arg)
                @value = arg
              end

              def inspect
                "<Vertex:Input:#{object_id} hash=#{hash_code} type=#{type} value=#{value}>"
              end
            end
          end
        end
      end
    end
  end
end
