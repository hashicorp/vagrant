module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          # Provides searching of a graph to determine if a
          # destination vertex is accessible from a given
          # root vertex.
          class Search
            class NoPathError < StandardError; end
            class InvalidVertex < StandardError
              attr_reader :vertex
              def initialize(v)
                super("Invalid vertex within path")
                @vertex = v
              end
            end

            include Util::HasLogger

            attr_reader :graph

            # Create a new Search instance
            #
            # @param graph [Graph] Graph used for searching
            def initialize(graph:)
              @m = Mutex.new
              @graph = graph
              @root = nil
            end

            # Generate a path from a given source vertex
            #
            # @param src [Vertex] Source vertex
            # @return [Array<Vertex>] path from source to destination
            # @raises [NoPathError] when no path can be determined
            def path(src, dst)
              @m.synchronize do
                logger.debug("finding path #{src} -> #{dst}")
                @root = src

                logger.debug("generating list of required vertices for path #{src} -> #{dst}")
                # Generate list of required vertices from the graph
                required_vertices = generate_path(src, dst)

                if required_vertices.nil?
                  raise NoPathError,
                    "Path generation failed to reach destination (#{dst&.type&.inspect})"
                end
                logger.debug("required vertices list generation complete for path #{src} -> #{dst}")

                # Remove all extraneous vertices
                (graph.vertices - required_vertices).each do |vrt|
                  graph.remove_vertex(vrt)
                end

                # Apply topological sort to the graph so we have
                # a proper for execution
                result = Array.new.tap do |path|
                  t = graph.topsort_iterator
                  until t.at_end?
                    path << t.forward
                  end
                end

                if result.first != src
                  raise NoPathError,
                    "Initial vertex is not source #{src} != #{result.first}"
                end

                if result.last != dst
                  raise NoPathError,
                    "Final vertex is not destination #{dst} != #{result.last}"
                end
                result
              end
            end

            protected

            def generate_path(src, dst)
              begin
                path = graph.shortest_path(src, dst)
                o = Array(path).map { |v|
                  "#{v} ->"
                }.join("\n")
                logger.debug("path generation #{src} -> #{dst}\n#{o}")
                if path.nil?
                  raise NoPathError,
                    "Path generation failed to reach destination (#{dst&.type&.inspect})"
                end
                expand_path(path, src, graph)
              rescue InvalidVertex => err
                graph.remove_vertex(err.vertex)
                retry
              end
            end

            def expand_path(path, src, graph)
              new_path = []
              path.each do |v|
                new_path << v
                next if !v.incoming_edges_required
                ins = graph.in_vertices(v)
                g = graph.dup
                g.remove_vertex(v)
                ins.each do |dst|
                  path = g.shortest_path(src, dst)
                  raise InvalidVertex.new(v) if path.nil?
                  path = expand_path(path, src, g)
                  new_path += path
                end
              end
              new_path
            end
          end
        end
      end
    end
  end
end
