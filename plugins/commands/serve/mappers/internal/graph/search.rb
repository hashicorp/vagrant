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
                    "Path generation failed to reach destination (source: #{src} destination: #{dst&.type&.inspect})"
                end
                logger.debug("required vertices list generation complete for path #{src} -> #{dst}")

                # Remove all extraneous vertices
                (graph.vertices - required_vertices).each do |vrt|
                  graph.remove_vertex(vrt)
                end

                if !graph.acyclic?
                  begin
                    # If the graph ends up with a cycle, attempt to
                    # draw the graph for inspection. We don't care if
                    # this fails as it's only for debugging and will
                    # only be successful if graphviz is installed.
                    require 'rgl/dot'
                    graph.write_to_graphic_file('jpg')
                  rescue
                    # ignore
                  end
                  logger.error("path generation for #{src} -> #{dst} resulted in cyclic graph")

                  raise NoPathError,
                    "Failed to create an acyclic graph for path generation"
                end

                # Apply topological sort to the graph so we have
                # a proper order for execution
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
                  "  #{v} ->"
                }.join("\n")
                logger.debug("path generation #{src} -> #{dst}\n#{o}")
                if path.nil?
                  raise NoPathError,
                    "Path generation failed to reach destination (#{dst&.type&.inspect})"
                end
                expand_path(path, src, graph)
              rescue InvalidVertex => err
                logger.debug("invalid vertex in path, removing (#{err.vertex})")
                graph.remove_vertex(err.vertex)
                retry
              end
            end

            def expand_path(path, src, graph)
              new_path = []
              path.each do |v|
                new_path << v
                next if !v.incoming_edges_required
                logger.debug("validating incoming edges for vertex #{v}")
                ins = graph.in_vertices(v)
                g = graph.clone
                g.remove_vertex(v)
                ins.each do |dst|
                  ipath = g.shortest_path(src, dst)
                  raise InvalidVertex.new(v) if ipath.nil? || ipath.empty?
                  ipath = expand_path(ipath, src, g)
                  new_path += ipath
                end
                logger.debug("incoming edge validation complete for vertex #{v}")
              end
              new_path
            end
          end
        end
      end
    end
  end
end
