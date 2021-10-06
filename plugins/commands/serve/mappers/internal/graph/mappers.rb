module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          # Represent given mappers and inputs as
          # graph.
          class Mappers
            INPUT_WEIGHT = 0
            OUTPUT_WEIGHT = 10
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
              if !output_type.is_a?(Class)
                raise TypeError,
                  "Expected output type to be `Class', got `#{output_type.class}'"
              end
              @final = output_type
              @inputs = Array(input_values).compact
              if !mappers.is_a?(CommandServe::Mappers)
                raise TypeError,
                  "Expected mapper to be `Mappers', got `#{mappers.class}'"
              end
              @mappers = mappers

              setup!
            end

            # Generate path and execute required mappers
            #
            # @return [Object] result
            def execute
              # Generate list of vertices to reach destination
              # from root, if possible
              search = Search.new(graph: graph)
              p = search.path(@root, @dst)

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
                args = search.graph.edges_in(v).map(&:value)
                v.call(*args)
              end

              # The resultant value will be stored within the
              # destination vertex
              @dst.value
            end

            protected

            # Setup the graph using the provided Mappers instance
            def setup!
              @graph = Graph.new
              # Create a root vertex to provide a single starting point
              @root = Graph::Vertex.new(value: :root)
              # Add the provided input values
              input_vertices = inputs.map do |input_value|
                iv = Graph::Vertex::Value.new(value: input_value)
                graph.add_weighted_edge(@root, iv, INPUT_WEIGHT)
                iv
              end
              # Also add the known values from the mappers instance
              input_vertices += mappers.known_arguments.map do |input_value|
                iv = Graph::Vertex::Value.new(value: input_value)
                graph.add_weighted_edge(@root, iv, INPUT_WEIGHT)
                iv
              end
              fn_inputs = Array.new
              fn_outputs = Array.new
              # Create vertices for all our registered mappers,
              # as well as their inputs and outputs
              mappers.mappers.each do |mapper|
                fn = Graph::Vertex::Method.new(callable: mapper)
                fn_inputs += mapper.inputs.map do |i|
                  iv = Graph::Vertex::Input.new(type: i.type)
                  graph.add_edge(iv, fn)
                  iv
                end
                ov = Graph::Vertex::Output.new(type: mapper.output)
                graph.add_edge(fn, ov)
                fn_outputs << ov
              end
              # Create an output vertex for our expected
              # result type
              @dst = Graph::Vertex::Output.new(type: final)
              # Add an edge from all our value vertices to
              # matching input vertices
              input_vertices.each do |iv|
                fn_inputs.each do |f_iv|
                  if iv.type == f_iv.type
                    if iv.type == Hashicorp::Vagrant::Sdk::FuncSpec::Value ||
                        f_iv.type == Hashicorp::Vagrant::Sdk::FuncSpec::Value
                      raise "wtf, #{self.inspect}"
                    end
                    graph.add_weighted_edge(iv, f_iv, INPUT_WEIGHT)
                  end
                end

                # If a value vertex matches the desired
                # output value, connect it directly
                if @dst.type == iv.type
                  graph.add_weighted_edge(iv, @dst, INPUT_WEIGHT)
                end
              end
              # Add an edge from all our output vertices to
              # matching input vertices
              fn_outputs.each do |f_ov|
                fn_inputs.each do |f_iv|
                  if f_ov.type == f_iv.type
                    if f_ov.type == Hashicorp::Vagrant::Sdk::FuncSpec::Value ||
                        f_iv.type == Hashicorp::Vagrant::Sdk::FuncSpec::Value
                      raise "wtf outs, #{self.inspect}"
                    end

                    graph.add_edge(f_ov, f_iv)
                  end
                end

                # If an output value matches the desired
                # output value, connect it directly
                if @dst.type == f_ov.type
                  graph.add_weighted_edge(f_ov, @dst, OUTPUT_WEIGHT)
                end
              end
              # Finalize the graphs so edges are properly
              # sorted by their weight
              graph.finalize!
            end
          end
        end
      end
    end
  end
end
