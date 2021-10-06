module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            # Vertex that represents a value
            class Value < Vertex
              # @return [Class] hash code for value
              def hash_code
                value.class
              end

              # @return [Class] type of the value
              def type
                value.class
              end

              def inspect
                "<Vertex:Value:#{object_id} hash=#{hash_code} type=#{type} value=#{value}>"
              end
            end
          end
        end
      end
    end
  end
end
