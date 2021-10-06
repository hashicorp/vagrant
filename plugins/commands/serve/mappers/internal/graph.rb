module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          autoload :Mappers, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/mappers").to_s
          autoload :Search, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/search").to_s
          autoload :Topological, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/topological").to_s
          autoload :Vertex, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex").to_s
          autoload :WeightedVertex, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/weighted_vertex").to_s

          # Default weight used for weighted vetices
          # when no weight is provided
          DEFAULT_WEIGHT = 1_000_000
          # Marker value used for lookups
          VERTEX_ID = :vertex_id

          # @return [Hash<Object, Vertex>] list of vertices within graph
          attr_reader :vertex_map
          # @return [Hash<Object, Hash<Object, Symbol>>] incoming adjecency list
          attr_reader :adjecency_in
          # @return [Hash<Object, Array<WeightedVertex>] weighted incoming adjecency list
          attr_reader :adjecency_in_weight
          # @return [Hash<Object, Hash<Object, Symbol>>] outgoing adjecency list
          attr_reader :adjecency_out
          # @return [Hash<Object, Array<WeightedVertex>] weighted outgoing adjecency list
          attr_reader :adjecency_out_weight

          # Create a new Graph
          def initialize
            @vertex_map = {}
            @adjecency_in = {}
            @adjecency_in_weight = {}
            @adjecency_out = {}
            @adjecency_out_weight = {}
            @m = Mutex.new
          end

          # @return [Array<Vertex>] list of vertices
          def vertices
            @m.synchronize do
              vertex_map.values
            end
          end

          # Create a copy of the current Graph
          #
          # @return [Graph]
          def copy
            @m.synchronize do
              self.class.new.tap do |g|
                # Copy our vertices list
                g.vertex_map.replace(vertex_map.dup)

                # Copy incoming edges list
                new_in = Hash.new.tap do |nin|
                  adjecency_in.each_pair do |k, v|
                    nin[k] = v.dup
                  end
                end
                g.adjecency_in.replace(new_in)

                # Copy outgoing edges list
                new_out = Hash.new.tap do |nout|
                  adjecency_out.each_pair do |k, v|
                    nout[k] = v.dup
                  end
                end
                g.adjecency_out.replace(new_out)

                # Copy incoming edge weights
                in_w = Hash.new.tap do |win|
                  adjecency_in_weight.each_pair do |k, v|
                    win[k] = v.dup
                  end
                end

                # Copy outgoing edge weights
                g.adjecency_in_weight.replace(in_w)
                out_w = Hash.new.tap do |wout|
                  adjecency_out_weight.each_pair do |k, v|
                    wout[k] = v.dup
                  end
                end
                g.adjecency_out_weight.replace(out_w)
              end
            end
          end

          # Create a reversed copy of the current Graph
          #
          # @return [Graph]
          def reverse
            @m.synchronize do
              self.class.new.tap do |g|
                # Copy our vertices list
                g.vertex_map.replace(vertex_map.dup)

                # Transfer incoming edges list to outgoing edges
                new_in = Hash.new.tap do |nin|
                  adjecency_in.each_pair do |k, v|
                    nin[k] = v.dup
                  end
                end
                g.adjecency_out.replace(new_in)

                # Transfer outgoing edges list to incoming edges
                new_out = Hash.new.tap do |nout|
                  adjecency_out.each_pair do |k, v|
                    nout[k] = v.dup
                  end
                end
                g.adjecency_in.replace(new_out)

                in_w = Hash.new.tap do |win|
                  adjecency_in_weight.each_pair do |k, v|
                    win[k] = v.dup
                  end
                end
                # Set out vertices as in
                g.adjecency_out_weight.replace(in_w)
                out_w = Hash.new.tap do |wout|
                  adjecency_out_weight.each_pair do |k, v|
                    wout[k] = v.dup
                  end
                end
                # Set in vertices as out
                g.adjecency_in_weight.replace(out_w)
              end
            end
          end

          # List of incoming vertices and their weights
          # to the given vertex
          #
          # @param v [Vertex]
          # @return [Hash<Vertex, Integer>]
          def weighted_edges_in(v)
            @m.synchronize do
              v = add_vertex(v)
              Hash.tap do |wei|
                Array(adjecency_in_weight[v.hash_code]).each do |vrt|
                  wei[vertex_map[vrt.hash_code]] = vrt.weight
                end
              end
            end
          end

          # List of outgoing vertices and their weights
          # from the given vertex
          #
          # @param v [Vertex]
          # @return [Hash<Vertex, Integer>]
          def weighted_edges_out(v)
            @m.synchronize do
              v = add_vertex(v)
              Hash.tap do |wei|
                Array(adjecency_out_weight[v.hash_code]).each do |vrt|
                  wei[vertex_map[vrt.hash_code]] = vrt.weight
                end
              end
            end
          end

          # List of incoming vertices to the given vertex
          #
          # @param v [Vertex]
          # @return [Array<Vertex>]
          def edges_in(v)
            @m.synchronize do
              v = add_vertex(v)
              adjecency_in_weight[v.hash_code].sort_by(&:weight).map do |vrt|
                vertex_map[vrt.hash_code]
              end
            end
          end

          # List of outgoing vertices from the given vertex
          #
          # @param v [Vertex]
          # @return [Array<Vertex>]
          def edges_out(v)
            @m.synchronize do
              v = add_vertex(v)
              adjecency_out_weight[v.hash_code].sort_by(&:weight).map do |vrt|
                vertex_map[vrt.hash_code]
              end
            end
          end

          # Add a vertex to the graph. Vertices are
          # registered by the vertex's hash code value,
          # so the returned object may not be the same
          # object that was provided.
          #
          # @param v [Vertex]
          # @return [Vertex]
          def add(v)
            @m.synchronize do
              add_vertex(v)
            end
          end

          # Remove a vertex from the graph
          #
          # @param v [Vertex]
          # @return [Vertex]
          def remove(v)
            @m.synchronize do
              v = add_vertex(v)
              vertex_map.delete(v.hash_code)

              adjecency_out.delete(v.hash_code)
              adjecency_in.delete(v.hash_code)

              adjecency_out_weight.delete(v.hash_code)
              adjecency_in_weight.delete(v.hash_code)

              adjecency_in.each_pair do |_, invrt|
                invrt.delete(v.hash_code)
              end
              adjecency_in_weight.values.each do |list|
                list.delete_if { |vrt| vrt.hash_code == v.hash_code }
              end

              adjecency_out.each_pair do |_, outvrt|
                outvrt.delete(v.hash_code)
              end
              adjecency_out_weight.values.each do |list|
                list.delete_if { |vrt| vrt.hash_code == v.hash_code }
              end

              v
            end
          end

          # Add an edge from one vertex to another
          #
          # @param from [Vertex]
          # @param to [Vertex]
          # @return [self]
          def add_edge(from, to)
            add_weighted_edge(from, to, DEFAULT_WEIGHT)
            self
          end

          # Add a weighted edge from one vertex to another
          #
          # @param from [Vertex]
          # @param to [Vertex]
          # @param weight [Integer]
          # @return [self]
          def add_weighted_edge(from, to, weight)
            @m.synchronize do
              from = add_vertex(from)
              to = add_vertex(to)
              adjecency_out[from.hash_code][to.hash_code] = VERTEX_ID
              adjecency_out_weight[from.hash_code] << WeightedVertex.new(
                code: to.hash_code,
                weight: weight
              )
              adjecency_in[to.hash_code][from.hash_code] = VERTEX_ID
              adjecency_in_weight[to.hash_code] << WeightedVertex.new(
                code: from.hash_code,
                weight: weight
              )
            end
            self
          end

          # Remove an edge from one vertex to another
          #
          # @param from [Vertex]
          # @param to [Vertex]
          # @return [self]
          def remove_edge(from, to)
            @m.synchronize do
              from = add_vertex(from)
              to = add_vertex(to)
              adjecency_in[to.hash_code].delete(from.hash_code)
              adjecency_in_weight[to.hash_code].delete_if { |vrt|
                vrt.hash_code == from.hash_code }
              adjecency_out[from.hash_code].delete(to.hash_code)
              adjecency_out_weight[from.hash_code].delete_if { |vrt|
                vrt.hash_code == to.hash_code }
            end
            self
          end

          # Finalize the graph for use. This will ensure all
          # edges are properly sorted if weighted.
          def finalize!
            # @m.synchronize do
            #   adjecency_in_weight.each_pair do |code, list|
            #     list.sort_by!(&:weight)
            #     adjecency_in[code] = Hash[list.map{ |w| [w.hash_code, VERTEX_ID] }]
            #   end
            #   adjecency_out_weight.each_pair do |code, list|
            #     list.sort_by!(&:weight)
            #     adjecency_out[code] = Hash[list.map{ |w| [w.hash_code, VERTEX_ID] }]
            #   end
            # end
            self
          end

          protected

          # Adds a vertex to the graph and initializes
          # edge data structures. If a hash code for the
          # vertex has already been registered, the registered
          # vertex will be returned (which may be different than
          # the provided vertex)
          #
          # @param v [Vertex]
          # @return [Vertex]
          def add_vertex(v)
            if !v.is_a?(Vertex)
              raise TypeError,
                "Expected type `Vertex', got `#{v.class}'"
            end
            if vertex_map.key?(v.hash_code)
              return vertex_map[v.hash_code]
            end
            adjecency_in[v.hash_code] = {}
            adjecency_in_weight[v.hash_code] = []
            adjecency_out[v.hash_code] = {}
            adjecency_out_weight[v.hash_code] = []
            vertex_map[v.hash_code] = v
          end
        end
      end
    end
  end
end
