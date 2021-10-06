module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          # Provides topological sorting of a Graph
          class Topological
            class NoRootError < StandardError; end
            class CycleError < StandardError; end

            attr_reader :graph

            # Create a new topological sorting instance
            #
            # @param graph [Graph] Graph used for sorting
            def initialize(graph:)
              @graph = graph.copy
              @m = Mutex.new
            end

            # Generate a topological sorted path of the defined
            # graph.
            #
            # @return [Array<Vertex>]
            # @raises [NoRootError, CycleError]
            def sort
              @m.synchronize do
                s = Stack.new

                graph.vertices.each do |v|
                  s.push(v) if graph.edges_in(v).size < 1
                end

                if s.size < 1
                  raise NoRootError,
                    "graph does not contain any root vertices"
                end

                kahn(s)
              end
            end

            protected

            # Sort the graph vertices using Kahn's algorithm
            #
            # @param s [Stack] Stack to hold vertices
            # @return [Array<Vertex>]
            # @raises [CycleError]
            def kahn(s)
              p = Queue.new
              while s.size > 0
                v = s.pop
                p.push(v)
                graph.edges_out(v).each do |next_v|
                  graph.remove_edge(v, next_v)
                  if graph.edges_in(next_v).size < 1
                    s.push(next_v)
                  end
                end
              end

              graph.vertices.each do |v|
                if graph.edges_in(v).size > 1 || graph.edges_out(v).size > 1
                  raise CycleError,
                    "graph contains at least one cycle"
                end
              end

              Array.new.tap do |path|
                while p.size > 0
                  path << p.pop
                end
              end
            end
          end
        end
      end
    end
  end
end
