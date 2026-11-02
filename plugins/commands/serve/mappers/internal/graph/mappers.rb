# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
            # Weight given to source vertex or initial value
            SOURCE_WEIGHT = 0
            # Weight given to the destination vertex
            FINAL_WEIGHT = 0
            # Weight given to output types matching final
            DST_WEIGHT = 0
            # Weight given to named input value vertices
            NAMED_VALUE_WEIGHT = 0
            # Weight given to input value vertices
            VALUE_WEIGHT = 10
            # Weight given to input vertices
            INPUT_WEIGHT = 20
            # Weight given to output vertices
            OUTPUT_WEIGHT = 20

            # @return [Graph] graph instance representing mappers
            attr_reader :graph
            # @return [Object] source input value
            attr_reader :source
            # @return [Array<Object>] input values
            attr_reader :inputs
            # @return [String] named input to prefer
            attr_reader :named
            # @return [Mappers] mappers instance executing against
            attr_reader :mappers
            # @return [Class] expected return type
            attr_reader :final
            # @return [Boolean] graph is fresh (not using cached vertex list)
            attr_reader :fresh
            # @return [Array<Proc>] list of callables used for Method vertices
            attr_reader :callables

            @previous = {}

            class << self
              # Register a valid path for a given source
              # and destination
              #
              # @param src [Class] source type
              # @param dst [Class] destination type
              # @param path [Array<Vertex>]
              def register(src, dst, path)
                begin
                  @previous[generate_key(src, dst)] = path
                rescue KeyError
                  nil
                end
              end

              # Remove an existing path registration
              #
              # @param src [Class] source type
              # @param dst [Class] destination type
              # @return [NilClass]
              def unregister(src, dst)
                @previous.delete(generate_key(src, dst))
                nil
              end

              # Fetch a path for a given source and destination
              # if it has been registered
              #
              # @param src [Class] source type
              # @param dst [Class] destination type
              # @return [Array<Vertex>, NilClass]
              def previous(src, dst)
                begin
                  @previous[generate_key(src, dst)]
                rescue KeyError
                  nil
                end
              end

              # Generate lookup key for given source
              # and destination
              #
              # @param src [Class] source
              # @param dst [Class] destination
              # @return [String]
              def generate_key(src, dst)
                "#{src} -> #{dst}"
              end
            end

            # Wrap a mappers instance into a graph with input values
            # and determine and execute required path for desired output
            #
            # @param output_type [Class] Expected return type
            # @param input_values [Array<Object>] Values provided for execution
            # @param mappers [Mappers] Mappers instance to use
            # @param named [String] Named input to prefer
            # @param source [Object] Source value for conversion (optional)
            def initialize(output_type:, input_values:, mappers:, named: nil, source: nil)
              if !output_type.nil? && !output_type.is_a?(Class) && !output_type.is_a?(Module)
                raise TypeError,
                  "Expected output type to be `Class', got `#{output_type.class}' (#{output_type})"
              end
              @final = output_type
              @source = source
              @inputs = Array(input_values)
              if !mappers.is_a?(CommandServe::Mappers)
                raise TypeError,
                  "Expected mapper to be `Mappers', got `#{mappers.class}'"
              end
              @mappers = mappers
              @callables = mappers.mappers
              @named = named.to_s
              @fresh = true

              # If we have a valid source type (and are not generating a value) check
              # if a path has already been registered for this source/destination
              # pair. If it has, we can fetch the callables out of the registered
              # path and build our graph only using that subset of callables
              if source != GENERATE_CLASS && self.class.previous(source, final)
                @callables = self.class.previous(source, final).find_all { |v|
                  v.is_a?(Vertex::Method)
                }.map(&:callable)
                # Since we built the graph using a registered path lookup, mark
                # this as non-fresh
                @fresh = false
              end

              setup!

              logger.debug { "new graph mappers instance created #{self}" }
              logger.debug { "graph: #{graph.inspect}" }
            end

            # Generate path and execute required mappers
            #
            # @return [Object] result
            def execute
              # Generate list of vertices to reach destination
              # from root, if possible
              search = Search.new(graph: graph)
              logger.debug { "searching for conversion path #{source ? source : inputs.first.class} -> #{final}" }
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

              # If we were not generating a value and the graph was fresh,
              # register this path lookup for future use.
              if source != GENERATE_CLASS && fresh
                self.class.register(source, final, p)
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
            rescue => err
              # If a failure was encountered and the graph was fresh
              # allow the error to continue bubbling up
              raise if fresh

              # If the graph is not fresh, unregister the cached path
              # and retry the mapping with the full graph
              logger.trace("search execution using cached path failed, retrying with full graph (#{err})")
              self.class.unregister(source, final)
              self.class.new(
                output_type: final,
                input_values: inputs,
                mappers: mappers,
                named: named,
                source: source
              ).execute
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
              @root = graph.add_vertex(Graph::Vertex::Root.new(value: :root))
              @root.weight = ROOT_WEIGHT
              # Add the provided input values
              input_vertices = []
              initial_value = true

              input_vertices += inputs.map do |input_value|
                if input_value == GENERATE
                  initial_value = false
                  next
                end
                if input_value.is_a?(Type::NamedArgument)
                  iv = graph.add_vertex(
                    Graph::Vertex::NamedValue.new(
                      name: input_value.name.to_s,
                      value: input_value.value
                    )
                  )
                  iv.weight = input_value.name.to_s == named ? NAMED_VALUE_WEIGHT : VALUE_WEIGHT
                else
                  iv = graph.add_vertex(Graph::Vertex::Value.new(value: input_value))
                  iv.weight = initial_value ? SOURCE_WEIGHT : VALUE_WEIGHT
                end
                # If this is the initial value and we are not generating a result,
                # then mark it as the origin value
                if initial_value
                  @origin = iv
                  logger.info("origin vertex has been set: #{@origin}")
                end

                initial_value = false
                graph.add_edge(@root, iv)
                iv
              end.compact
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
              callables.each do |mapper|
                fn = graph.add_vertex(Graph::Vertex::Method.new(callable: mapper))
                fn_inputs += mapper.inputs.map do |i|
                  iv = graph.add_vertex(Graph::Vertex::Input.new(type: i.type, origin_restricted: i.origin_restricted))
                  iv.weight = INPUT_WEIGHT + fn.extra_weight
                  graph.add_edge(iv, fn)
                  iv
                end
                ov = graph.add_vertex(Graph::Vertex::Output.new(type: mapper.output))
                ov.weight = (mapper.output == final ? DST_WEIGHT : OUTPUT_WEIGHT) + fn.extra_weight
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
                  if f_iv.origin_value_only? && iv != @origin
                    next
                  end
                  if iv.type == f_iv.type || iv.type.ancestors.include?(f_iv.type)
                    graph.add_edge(iv, f_iv)
                  end
                end

                # If a value vertex matches the desired
                # output value, connect it directly
                if @dst.type == iv.type # || iv.type.ancestors.include?(@dst.type)
                  graph.add_edge(iv, @dst)
                end
              end
              # Add an edge from all our output vertices to
              # matching input vertices
              fn_outputs.each do |f_ov|
                fn_inputs.each do |f_iv|
                  next if f_iv.origin_value_only?
                  if f_ov.type == f_iv.type || f_ov.type.ancestors.include?(f_iv.type)
                    graph.add_edge(f_ov, f_iv)
                  end
                end

                # If an output value matches the desired
                # output value, connect it directly
                if @dst.type == f_ov.type || f_ov.type.ancestors.include?(@dst)
                  if @dst.type != f_ov.type
                    f_ov.weight += 1000
                  end
                  graph.add_edge(f_ov, @dst)
                end
              end

              # The output attached to our destination should be
              # terminated at the destiation. If it has any out
              # edges, remove those vertices (which has the bonus
              # of helping to prevent cycles)
              graph.each_in_vertex(@dst) do |vrt|
                graph.each_out_vertex(vrt) do |ov|
                  next if ov == @dst
                  graph.remove_edge(vrt, ov)
                end
              end
            end
          end
        end
      end
    end
  end
end
