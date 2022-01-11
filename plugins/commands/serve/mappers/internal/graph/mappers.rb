module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          # Represent given mappers and inputs as
          # graph.
          class Mappers
            include Util::HasLogger
            # Weight given to root vertex
            ROOT_WEIGHT = 0
            # Weight given to the destination vertex
            FINAL_WEIGHT = 0
            # Weight given to first input value vertex
            BASE_WEIGHT = 0
            # Weight given to input value vertices
            VALUE_WEIGHT = 10
            # Weight given to input vertices
            INPUT_WEIGHT = 20
            # Weight given to output vertices
            OUTPUT_WEIGHT = 20

            # @return [Graph] graph instance representing mappers
            attr_reader :graph
            # @return [Array<Object>] input values
            attr_reader :inputs
            # @return [Mappers] mappers instance executing against
            attr_reader :mappers
            # @return [Class] expected return type
            attr_reader :final

            # Wrap a mappers instance into a graph with input values
            # and determine and execute required path for desired output
            #
            # @param output_type [Class] Expected return type
            # @param input_values [Array<Object>] Values provided for execution
            # @param mappers [Mappers] Mappers instance to use
            def initialize(output_type:, input_values:, mappers:)
              if !output_type.nil? && !output_type.is_a?(Class) && !output_type.is_a?(Module)
                raise TypeError,
                  "Expected output type to be `Class', got `#{output_type.class}' (#{output_type})"
              end
              @final = output_type
              @inputs = Array(input_values)
              if !mappers.is_a?(CommandServe::Mappers)
                raise TypeError,
                  "Expected mapper to be `Mappers', got `#{mappers.class}'"
              end
              @mappers = mappers

              setup!

              logger.debug("new graph mappers instance created #{self}")
              logger.debug("graph: #{graph.inspect}")
            end

            # Generate path and execute required mappers
            #
            # @return [Object] result
            def execute
              # Generate list of vertices to reach destination
              # from root, if possible
              search = Search.new(graph: graph)
              logger.debug("searching for conversion path #{inputs.first} -> #{final}")
              p = search.path(@root, @dst)

              logger.debug {
                sp = p.map{ |v|
                  v = v.to_s.slice(0, 100) + "...>" if v.to_s.length > 100
                  v
                }.join(" ->\n  ")
                "found execution path:\n  #{sp}"
              }
              # Call root first and validate it was
              # actually root. The value is a stub,
              # so it's not saved.
              result = p.shift.call
              if result != :root
                raise "Initial vertex is not root. Expected `:root', got `#{result}'"
              end

              # Execute each vertex in the path
              p.each do |v|
                # The argument list required by the current
                # vertex will be defined by its incoming edges
                args = search.graph.in_vertices(v).map(&:value)
                v.call(*args)
              end

              # The resultant value will be stored within the
              # destination vertex
              @dst.value
            end

            def to_s
              "<Graph:Mappers output_type=#{final} input_values=#{inputs.map(&:class)}>"
            end

            def inspect
              "<#{self.class.name}:#{object_id} output_type=#{final} input_values=#{inputs} graph=#{graph}>"
            end

            protected

            # Setup the graph using the provided Mappers instance
            def setup!
              @graph = Graph.new
              # Create a root vertex to provide a single starting point
              @root = graph.add_vertex(Graph::Vertex.new(value: :root))
              @root.weight = ROOT_WEIGHT
              # Add the provided input values
              i = 0
              input_vertices = inputs.map do |input_value|
                iv = graph.add_vertex(Graph::Vertex::Value.new(value: input_value))
                iv.weight = i == 0 ? BASE_WEIGHT : VALUE_WEIGHT
                i += 1
                graph.add_edge(@root, iv)
                iv
              end
              # Also add the known values from the mappers instance
              input_vertices += mappers.known_arguments.map do |input_value|
                iv = graph.add_vertex(Graph::Vertex::Value.new(value: input_value))
                iv.weight = VALUE_WEIGHT
                graph.add_edge(@root, iv)
                iv
              end
              fn_inputs = Array.new
              fn_outputs = Array.new
              # Create vertices for all our registered mappers,
              # as well as their inputs and outputs
              mappers.mappers.each do |mapper|
                fn = graph.add_vertex(Graph::Vertex::Method.new(callable: mapper))
                fn_inputs += mapper.inputs.map do |i|
                  iv = graph.add_vertex(Graph::Vertex::Input.new(type: i.type))
                  iv.weight = INPUT_WEIGHT
                  graph.add_edge(iv, fn)
                  iv
                end
                ov = graph.add_vertex(Graph::Vertex::Output.new(type: mapper.output))
                ov.weight = OUTPUT_WEIGHT
                graph.add_edge(fn, ov)
                fn_outputs << ov
              end
              # Create an output vertex for our expected
              # result type
              @dst = graph.add_vertex(Graph::Vertex::Final.new(type: final))
              @dst.weight = FINAL_WEIGHT

              # Add an edge from all our value vertices to
              # matching input vertices
              input_vertices.each do |iv|
                fn_inputs.each do |f_iv|
                  if iv.type == f_iv.type || iv.type.ancestors.include?(f_iv.type)
                    graph.add_edge(iv, f_iv)
                  end
                end

                # If a value vertex matches the desired
                # output value, connect it directly
                if @dst.type == iv.type || iv.type.ancestors.include?(@dst.type)
                  graph.add_edge(iv, @dst)
                end
              end
              # Add an edge from all our output vertices to
              # matching input vertices
              fn_outputs.each do |f_ov|
                fn_inputs.each do |f_iv|
                  if f_ov.type == f_iv.type || f_ov.type.ancestors.include?(f_iv.type)
                    graph.add_edge(f_ov, f_iv)
                  end
                end

                # If an output value matches the desired
                # output value, connect it directly
                if @dst.type == f_ov.type || f_ov.type.ancestors.include?(@dst)
                  graph.add_edge(f_ov, @dst)
                end
              end
            end
          end
        end
      end
    end
  end
end
