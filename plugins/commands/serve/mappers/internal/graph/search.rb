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

                # We know the root is our final destination, so flop the graph before searching
                graph.reverse!

                # Perform an initial DFS to prune the graph down
                vertices = []
                descender = lambda { |v|
                  graph.depth_first_visit(v) { |vrt|
                    vertices << vrt
                  }
                  vertices.uniq!
                  vertices.each do |vrt|
                    if vrt.incoming_edges_required
                      graph.out_vertices(vrt).each do |ov|
                        if !vertices.include?(ov)
                          descender.call(ov)
                        end
                      end
                    end
                  end
                }

                descender.call(dst)

                # Remove excess vertices from the graph
                (graph.vertices - vertices).each { |v|
                  graph.remove_vertex(v)
                }

                logger.trace("graph after DFS reduction:\n#{graph.reverse.inspect}")
                logger.trace("generating list of required vertices for path #{src} -> #{dst}")

                if !graph.vertices.include?(src)
                  raise NoPathError,
                    "Graph no longer includes source vertex #{src}"
                end

                if !graph.vertices.include?(dst)
                  raise NoPathError,
                    "Graph no longer includes destination vertex #{dst}"
                end
                # Generate list of required vertices from the graph
                required_vertices = generate_path(dst, src)

                # If not vertices were returned, then the path generation failed
                if required_vertices.nil?
                  raise NoPathError,
                    "Path generation failed to reach destination (#{src} -> #{dst&.type&.inspect})"
                end

                logger.trace("required vertices list generation complete for path #{src} -> #{dst}")

                # Remove all extraneous vertices
                (graph.vertices - required_vertices).each do |vrt|
                  graph.remove_vertex(vrt)
                end

                graph.reverse!
                graph.break_cycles!(src) if !graph.acyclic?

                logger.debug("graph after acyclic breakage:\n#{graph.reverse.inspect}")

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
            rescue NoPathError
              if ENV["VAGRANT_LOG_MAPPER"].to_s != ""
                begin
                  require 'rgl/dot'
                  graph.reverse.write_to_graphic_file('jpg', 'graph-no-path')
                rescue
                  #
                end
              end
              raise
            end

            protected

            def generate_path(src, dst)
              begin
                path = graph.shortest_path(src, dst)
                o = Array(path).reverse.map { |v|
                  "  #{v} ->"
                }.join("\n")
                logger.trace("path generation #{dst} -> #{src}\n#{o}")
                if path.nil?
                  raise NoPathError,
                    "Path generation failed to reach destination (#{dst} -> #{src})"
                end
                expand_path(path, dst, graph)
              rescue InvalidVertex => err
                logger.trace("invalid vertex in path, removing (#{err.vertex})")
                graph.remove_vertex(err.vertex)
                retry
              end
            end

            def expand_path(path, dst, graph)
              new_path = []
              path.each do |v|
                new_path << v
                next if !v.incoming_edges_required
                logger.trace("validating incoming edges for vertex #{v}")
                outs = graph.out_vertices(v)
                g = graph.clone
                g.remove_vertex(v)
                outs.each do |src|
                  ipath = g.shortest_path(src, dst)
                  if ipath.nil? || ipath.empty?
                    logger.trace("failed to find validating path from #{dst} -> #{src}")
                    raise InvalidVertex.new(v)
                  else
                    logger.trace("found validating path from #{dst} -> #{src}")
                  end
                  ipath = expand_path(ipath, dst,  g)
                  new_path += ipath
                end
                logger.trace("incoming edge validation complete for vertex #{v}")
              end
              new_path
            end
          end
        end
      end
    end
  end
end
