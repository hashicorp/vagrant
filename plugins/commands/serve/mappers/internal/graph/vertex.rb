# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          # Represents a vertex within the graph
          class Vertex
            autoload :Final, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/final").to_s
            autoload :Input, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/input").to_s
            autoload :Method, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/method").to_s
            autoload :NamedValue, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/named_value").to_s
            autoload :Output, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/output").to_s
            autoload :Root, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex/root").to_s
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
              object_id
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

            # Determine if provided vertex is equivalent
            #
            # @param [Vertex]
            # @return [Boolean]
            def ==(v)
              return false if !v.respond_to?(:hash_code)
              v.hash_code == hash_code
            end
            alias_method :eql?, :==

            # Generate a hash for the given vertex. This is used
            # to uniquely identify a vertex within a Hash.
            #
            # @return [Integer]
            def hash
              hash_code.to_s.chars.map(&:ord).sum.hash
            end

            # @return [String]
            def to_s
              "<Vertex value=#{value} hash=#{hash_code}>"
            end

            # @return [String]
            def inspect
              "<#{self.class.name} value=#{value} hash=#{hash_code}>"
            end
          end
        end
      end
    end
  end
end
