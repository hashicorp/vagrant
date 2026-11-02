# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
                logger.debug { "finding path #{src} -> #{dst}" }

                # Mark the root of our graph which will be used later
                @root = src

                # When searching for a path in the graph, we will be looking
                # for the shortest path. Since we know the desired final
                # destination, we want to use that as our starting point
                # and attempt to find a path from that destination vertex
                # to the source vertex. So we start by reversing the graph
                graph.reverse!

                # Perform an initial DFS to prune the graph down. This will remove any
                # vertices which are not connected to the root of the graph (which will
                # be the destination since we reversed the graph). The reason we do this
                # is to reduce the overall size of the graph before generating our path,
                # and to ensure that the both ends of the graph are still available after
                # the pruning.
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

                # Since the destination is now the "root" of our reversed graph,
                # we want to start our search from there to generate the list
                # of verticies it can connect to.
                descender.call(dst)

                # Remove excess vertices from the graph
                (graph.vertices - vertices).each { |v|
                  graph.remove_vertex(v)
                }

                logger.trace { "graph after DFS reduction:\n#{graph.reverse.inspect}" }
                logger.trace { "generating list of required vertices for path #{src} -> #{dst}" }

                # If the graph no longer contains the source vertex (this is the root of the
                # non-reversed graph) then it is impossible to generate a valid path.
                if !graph.vertices.include?(src)
                  raise NoPathError,
                    "Graph no longer includes source vertex #{src} (#{src} -> #{dst})"
                end

                # This should not happen since we start our DFS from the destination vertex
                # but we keep this sanity check regardless.
                if !graph.vertices.include?(dst)
                  raise NoPathError,
                    "Graph no longer includes destination vertex #{dst} (#{src} -> #{dst})"
                end
                # Generate list of required vertices from the graph
                required_vertices = generate_path(dst, src)

                # If no vertices were returned, then the path generation failed
                if required_vertices.nil?
                  raise NoPathError,
                    "Path generation failed to reach destination (#{src} -> #{dst&.type&.inspect})"
                end

                logger.trace { "required vertices list generation complete for path #{src} -> #{dst}" }

                # Now that we have a path, remove all extraneous vertices
                # from the graph. We're going to use the graph to provide
                # us a proper ordering of the vertices below
                (graph.vertices - required_vertices).each do |vrt|
                  graph.remove_vertex(vrt)
                end

                # Reverse the graph so the direction of the graph is in its
                # original state.
                graph.reverse!

                # Check if the graph is acyclic. If it is not, break any cycles found in the graph.
                graph.break_cycles!(src) if !graph.acyclic?

                logger.debug { "graph after acyclic breakage:\n#{graph.reverse.inspect}" }

                # Apply topological sort to the graph so we have
                # a proper order for execution. This is required
                # to ensure that all inputs for a given vertex are
                # available before executing it.
                result = Array.new.tap do |path|
                  t = graph.topsort_iterator
                  until t.at_end?
                    path << t.forward
                  end
                end

                # If the first vertex of the path is not the expected source,
                # or the last vertex is not the expected destination, then
                # a valid path was not found. Even though we generated our
                # list of required vertices, this can still occur if the
                # resultant graph included any cycles, and breaking the cycle(s)
                # resulted in orphaned vertices.
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

            # Generate a list of required vertices for making a
            # path from the given source vertex to the given
            # destination vertex.
            #
            # @param src [Vertex] source vertex
            # @param dst [Vertex] destination vertex
            # @return [Array<Vertex>, NilClass]
            def generate_path(src, dst)
              begin
                # Find the shortest path based edge weights. Since
                # we are generating a path against the reversed graph,
                # the source is our desired destination vertex and the
                # destination is the source vertex.
                path = graph.shortest_path(src, dst)
                logger.trace {
                  o = Array(path).reverse.map { |v|
                    "  #{v} ->"
                  }.join("\n")
                  "path generation #{dst} -> #{src}\n#{o}"
                }
                if path.nil?
                  raise NoPathError,
                    "Path generation failed to reach destination (#{dst} -> #{src})"
                end
                # Once we have the path, we need to expand the
                # path to ensure that all vertices in the path
                # are fully reachable, and if any vertices are
                # missing that they are added
                expand_path(path, dst, graph)
              rescue InvalidVertex => err
                # An invalid vertex will be flagged when path expansion exposes
                # a vertex which requires all incoming edges and all the edges
                # cannot reach the destination vertex. When this happens, we
                # remove that vertex from the graph and then retry the path
                # generation.
                logger.trace { "invalid vertex in path, removing (#{err.vertex})" }
                graph.remove_vertex(err.vertex)
                retry
              end
            end

            # Expand a given path of vertices by iterating through
            # the provided path and validating all required vertices
            # are in the path for any vertices which require all incoming
            # edges. The result will be the list of original vertices
            # plus all additional vertices found to be missing.
            #
            # @param path [Array<Vertex>] current path
            # @param dst [Vertex]
            def expand_path(path, dst, graph)
              new_path = path.dup
              path.each do |v|
                # Only inspect vertices that require all
                # incoming edges
                next if !v.incoming_edges_required
                logger.trace { "validating incoming edges for vertex #{v}" }
                # Since we are using a reversed graph, the incoming edges are now
                # outgoing edges, so we graph the out vertices
                outs = graph.out_vertices(v)
                # Make a clone of the graph so we can modify it without affecting
                # the original
                g = graph.clone
                # Remove the original vertex we are currently inspecting from
                # the cloned graph. This is done to prevent generating a cycle
                # where the vetex is required in the path to reach the destination
                g.remove_vertex(v)
                # Now we find the path from each vertex to the destination
                outs.each do |src|
                  # Since inputs can support named arguments, temporarily update
                  # weights of value vertices.
                  ipath = reweight_for(src, g) do |ig|
                    ig.shortest_path(src, dst)
                  end
                  # Remove any other incoming edges to this input
                  # (graph.out_vertices(src) - [ipath.first]).each do |dv|
                  #   graph.remove_edge(src, dv)
                  # end

                  # If no path was found an exception is raised that the vertex
                  # in the path (this is the original vertex from the first loop)
                  # is not valid within the path.
                  if ipath.nil? || ipath.empty?
                    logger.trace { "failed to find validating path from #{dst} -> #{src}" }
                    raise InvalidVertex.new(v)
                  else
                    logger.trace { "found validating path from #{dst} -> #{src}" }
                  end
                  # Remove any vertices that already exist in our final collection
                  # so we don't duplicate the inspection on them
                  ipath = ipath - new_path
                  if !ipath.empty?
                    # Since we have new vertices we need to expand them to
                    # ensure that they all have valid paths to the destination.
                    # The graph provided here is our modified clone to prevent
                    # a cycle where the original vertex is required
                    ipath = expand_path(ipath, dst,  g)
                    # And now we add any new vertices which were discovered to
                    # be required
                    new_path |= ipath
                  end
                end
                logger.trace { "incoming edge validation complete for vertex #{v}" }
              end
              new_path
            end

            # Modify the weights of value type vertices when the given
            # vertex is a Vertex::Input and has a name defined. All
            # value vertices will have their weight reset to the default
            # value weight, and if a Vertex::NamedValue exists with a
            # matching name, it will have the NAMED_VALUE_WEIGHT
            # applied. After the given block is executed, the value
            # vertices will have their original weights re-applied.
            #
            # Since value vertices are identified by type, only
            # one value of any type may exist in the graph. However,
            # if the value is named, then multiple values of the same
            # type may exist in the graph. For instance, with named
            # values two strings could be provided, one named "local_path"
            # and another named "remote_path". If a mapper function is
            # only interested in the value of the "remote_path", it
            # can include that name within its input definition. Then
            # this method can be used to prefer the name string argument
            # "remote_path" over the "local_path" named argument, or
            # just a regular string value.
            #
            # @param vertex [Vertex] source vertex
            # @param graph [Graph] graph to modify
            # @yieldparam [Graph] modified graph (passed instance, not a copy)
            # @yield block to execute
            # @return [Object] result of block
            def reweight_for(vertex, graph)
              original_weights = {}
              begin
                if vertex.is_a?(Vertex::Input) && vertex.name
                  graph.each_vertex do |v|
                    next if !v.is_a?(Vertex::Value)
                    original_weights[v] = v.weight
                    if v.name.to_s == vertex.name.to_s
                      v.weight = Mappers::NAMED_VALUE_WEIGHT
                    else
                      v.weight = Mappers::VALUE_WEIGHT
                    end
                  end
                end
                yield graph
              ensure
                # Set the weights of the value vertices back to
                # their original values
                original_weights.each do |v, w|
                  v.weight = w
                end
              end
            end
          end
        end
      end
    end
  end
end
