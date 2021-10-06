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

            # Value used for marking visited vertices
            VERTEX_ID = :vertex

            attr_reader :graph, :root, :visited

            # Create a new DFS instance
            #
            # @param graph [Graph] Graph used for searching
            def initialize(graph:)
              @graph = graph.copy
              @m = Mutex.new
              @root = nil
              @visited = nil
            end

            # Provide a list of vertices not visited to build
            # the generated path. If no path has been generated,
            # it will return an empty value by default.
            #
            # @return [Array<Vertex>] list of vertices
            def orphans
              @m.synchronize do
                load_orphans
              end
            end

            # Generate a path from the given source vertex to
            # the given destination vertex using a depth first
            # search algorithm.
            #
            # @param src [Vertex] Source vertex
            # @param dst [Vertex] Destination vertex
            # @return [Array<Vertex>] path from source to destination
            # @raises [NoPathError] when no path can be determined
            def path(src, dst)
              @m.synchronize do
                @root = src
                @visited = {}
                stack = Stack.new
                stack.push(src)

                p = find_path(src, dst, stack)

                if Array(p).empty?
                  @visited = nil
                  raise NoPathError,
                    "failed to determine valid path"
                end

                # Now ensure our final path is in the correct order
                # based on edge defined dependencies
                load_orphans.each do |v|
                  graph.remove(v)
                end
                t = Topological.new(graph: graph)
                t.sort
              end
            end

            protected

            # Find path from source to destination
            #
            # @param src [Vertex] Source vertex
            # @param dst [Vertex] Destination vertex
            # @param s [Stack] Stack for holding path information
            # @return [Array<Vertex>, nil] list of vertices or nil if not found
            def find_path(src, dst, s)
              # If we have reached our destination then it's
              # time to mark vertices included in the final
              # path as visited and return the path
              if src == dst
                p = s.values
                p.each do |v|
                  visited[v.hash_code] = VERTEX_ID
                end
                return p
              end

              graph.edges_out(src).each do |v|
                # If the incoming edges don't define dependencies
                # then we only care about a single path through
                # the vertex
                if !v.incoming_edges_required
                  if s.include?(v)
                    next
                  end
                  s.push(v)
                  if p = find_path(v, dst, s)
                    return p
                  end
                  s.pop
                  next
                end

                # Since the incoming edges define dependencies
                # we need to validate they are reachable from
                # root before we continue attempting to build
                # the path
                req_paths = []
                if graph.edges_out(v).size > 1
                  d = self.class.new(graph: graph.reverse)
                  begin
                    p = d.path(dst, v)
                    req_paths << p
                  rescue NoPathError
                    next
                  end
                end


                failed = false
                graph.edges_in(v).each do |in_v|
                  # This was our initial path here so ignore
                  if src.hash_code == in_v.hash_code
                    next
                  end

                  # Create a new graph but reverse the direction
                  new_g = graph.reverse
                  # Remove edges from the vertex except for the
                  # one we are currently processing
                  new_g.edges_out(v).each do |out_v|
                    if out_v.hash_code == in_v.hash_code
                      next
                    end
                    new_g.remove_edge(v, out_v)
                  end

                  # Create a new DFS to search using the reversed
                  # graph
                  new_d = self.class.new(graph: new_g)
                  begin
                    # Attempt to find a path from the vertex back
                    # to root
                    p = new_d.path(v, root)
                    req_paths << p
                  rescue NoPathError
                    # If a path could not be found, mark failed
                    # and bail
                    failed = true
                    break
                  end
                end

                # If all the incoming edges couldn't be satisfied
                # then we ignore this vertex and move on
                if failed
                  next
                end

                # All the incoming edges could be satisfied so
                # we push this vertex on the stack and continue
                # down the current path
                s.push(v)

                # If we were able to reach the destination on
                # this path, we now need to add in the extra
                # paths generated to satisfy the edge requirements
                if p = find_path(v, dst, s)
                  # Store the position of the vertex we are processing
                  # in the path so we can properly cut and glue the path
                  pos = p.index(v)
                  # Cut the path prior to our current vertex
                  path_start = p.slice(0, pos)

                  # Now walk through each extra path and add any vertices
                  # that have not yet been seen
                  req_paths.each do |extra_path|
                    # The extra path originated from a reversed graph, so
                    # reverse this path before processing
                    extra_path.reverse.each do |extra_v|
                      if visited.key?(extra_v.hash_code)
                        next
                      end
                      visited[extra_v.hash_code] = VERTEX_ID
                      path_start << extra_v
                    end
                  end

                  # Now glue the remaining path to our modified start
                  # path and return the result
                  return path_start + p.slice(pos, p.size)
                end
                # If we made it here the vertex isn't part of a valid
                # path so pop it off the stack and continue
                s.pop
              end

              # If we have nothing left to process, return nothing
              nil
            end

            def load_orphans
              if visited.nil?
                return []
              end
              graph.vertices.map do |v|
                v if !visited.key?(v.hash_code)
              end.compact
            end

          end
        end
      end
    end
  end
end
