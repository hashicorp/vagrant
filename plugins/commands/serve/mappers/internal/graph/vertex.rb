require 'securerandom'

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          # Represents a vertex within the graph
          class Vertex
            autoload :Input, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/input").to_s
            autoload :Method, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/method").to_s
            autoload :Output, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/output").to_s
            autoload :Value, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/value").to_s
            # @return [Object] value of vertex
            attr_reader :value

            # Create a new vertex
            #
            # @param value [Object]
            def initialize(value:)
              @value = value
            end

            # Hash code of the vertex. Vertices
            # are unique within a graph based on
            # their hash code value. By default,
            # the `#object_id` is used
            def hash_code
              @code ||= SecureRandom.uuid
            end

            # By default, only a single edge must
            # be fulfilled to allow the path through
            # the vertex
            def incoming_edges_required
              false
            end

            # Executes the vertex if applicable
            def call(*_)
              value
            end

            def inspect
              "<Vertex:#{object_id} hash=#{hash_code} value=#{value}>"
            end
          end
        end
      end
    end
  end
end
