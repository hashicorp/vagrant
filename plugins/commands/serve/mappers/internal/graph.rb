# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "rgl/adjacency"
require "rgl/traversal"
require "rgl/dijkstra"
require "rgl/topsort"

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph < RGL::DirectedAdjacencyGraph

          # This iterator is used for detecting and breaking cycles
          # discovered within the graph using the DFS graph visitor
          # concept
          class CycleDeletorIterator < RGL::DFSVisitor
            # Create a new iterator instance. Store the graph
            # for later inspection use
            def initialize(graph, *_)
              @graph = graph
              super
            end

            # Examines the vertex to detect any cycles. If an
            # adjacent edge has already been visited then we
            # remove the edge to break the cycle.
            def handle_examine_vertex(u)
              graph.each_adjacent(u) do |v|
                if v.is_a?(Vertex::Output) && color_map[v] != :WHITE
                  graph.remove_edge(u, v)
                end
              end
            end
          end

          autoload :Mappers, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/mappers").to_s
          autoload :Search, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/search").to_s
          autoload :Vertex, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/vertex").to_s
          autoload :WeightedVertex, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph/weighted_vertex").to_s

          include Util::HasLogger

          # Default weight used for weighted vetices
          # when no weight is provided
          DEFAULT_WEIGHT = 1000

          def initialize(*_)
            @vertex_map = {}
            super
          end

          def initialize_copy(orig)
            super
            @vertex_map = orig.instance_eval { @vertex_map }.dup
            @vertices_dict = @vertices_dict.dup
            @vertices_dict.keys.each do |v|
              edges = @vertices_dict[v]
              @vertices_dict[v] = {in: edges[:in].dup, out: edges[:out].dup}
            end
          end

          def to_a
            @vertices_dict.keys
          end

          def each_out_vertex(v, &block)
            v = vertex_for(v)
            if !has_vertex?(v)
              raise "No vertex `#{v}' found in graph"
            end
            @vertices_dict[v][:out].each(&block)
          end
          alias :each_adjacent :each_out_vertex

          def out_vertices(v)
            v = vertex_for(v)
            if !has_vertex?(v)
              raise "No vertex `#{v}' found in graph"
            end
            @vertices_dict[v][:out].to_a
          end
          alias :adjacent_vertices :out_vertices

          def out_degree(v)
            v = vertex_for(v)
            if !has_vertex?(v)
              raise "No vertex `#{v}' found in graph"
            end
            @vertices_dict[v][:out].size
          end

          def each_in_vertex(v, &block)
            v = vertex_for(v)
            if !has_vertex?(v)
              raise "No vertex `#{v}' found in graph"
            end
            @vertices_dict[v][:in].each(&block)
          end

          def in_vertices(v)
            v = vertex_for(v)
            if !has_vertex?(v)
              raise "No vertex `#{v}' found in graph"
            end
            @vertices_dict[v][:in].to_a
          end

          def in_degree(v)
            v = vertex_for(v)
            if !has_vertex?(v)
              raise "No vertex `#{v}' found in graph"
            end
            @vertices[v][:in].size
          end

          def vertices
            @vertices_dict.keys
          end

          def each_vertex(&block)
            vertices.each(&block)
          end

          def num_vertices
            @vertices_dict.size
          end

          def num_edges
            @vertices_dict.each_value.inject(0) do |count, edges|
              count + edges[:out].size
            end
          end

          def has_edge?(u, v)
            u = vertex_for(u)
            v = vertex_for(v)
            has_vertex?(u) && @vertices_dict[u][0].include?(v)
          end

          def add_vertex(v)
            if !v.is_a?(Vertex)
              raise TypeError,
                "Expected type `Vertex', got `#{v.class}'"
            end
            if @vertex_map.key?(v.hash_code)
              v = @vertex_map[v.hash_code]
            else
              if !v.is_a?(WeightedVertex)
                v = WeightedVertex.new(v, weight: DEFAULT_WEIGHT)
              end
              @vertex_map[v.hash_code] = v
            end

            @vertices_dict[v] ||= {
              in: @edgelist_class.new,
              out: @edgelist_class.new,
            }
            v
          end

          def add_edge(u, v)
            u = add_vertex(u) # ensure key
            v = add_vertex(v) # ensure key
            basic_add_edge(u, v)
          end

          def remove_vertex(v)
            v = vertex_for(v)
            if has_vertex?(v)
              edges = @vertices_dict[v]
              @vertices_dict.delete(v)
              edges[:in].each do |parent|
                @vertices_dict[parent][:out].delete(v)
              end
              edges[:out].each do |child|
                @vertices_dict[child][:in].delete(v)
              end
              @vertex_map.delete(v.hash_code)
            end
            v
          end

          def remove_edge(u, v)
            u = vertex_for(u)
            v = vertex_for(v)
            if has_vertex?(u) && has_vertex?(v)
              if @vertices_dict[u][:out].delete?(v)
                @vertices_dict[v][:in].delete(u)
              end
            end
            self
          end

          def edgelist_class=(klass)
            @vertices_dict.keys.each do |v|
              edges = @vertices_dict[v]
              @vertices_dict[v] = {
                in: klass.new(edges[:in].to_a),
                out: klass.new(edges[:out].to_a),
              }
            end
            self
          end

          def reverse
            result = clone
            result.reverse!
          end

          def reverse!
            @vertices_dict.keys.each do |v|
              edges = @vertices_dict[v]
              @vertices_dict[v] = {
                in: edges[:out],
                out: edges[:in],
              }
            end
            self
          end

          def break_cycles!(src)
            depth_first_visit(src, CycleDeletorIterator.new(self)) { true }
          end

          def shortest_path(source, target)
            dijkstra_shortest_path(edge_weights_map, source, target)
          end

          def shortest_paths(source, target)
            dijkstra_shortest_paths(edge_weights_map, source, target)
          end

          def edge_weights_map
            Hash.new.tap do |edge_map|
              each_edge do |*edges|
                w = edges.map(&:weight).inject(&:+)
                if edges.first.respond_to?(:type) && edges.last.respond_to?(:type)
                  if edges.first.type != edges.last.type
                    w += 200
                    extra = edges.first.type.ancestors.index(edges.last.type)
                    if extra.nil?
                      extra = edges.last.type.ancestors.index(edges.first.type)
                    end
                    w += extra.to_i
                  end
                end
                edge_map[edges] = w
              end
            end
          end

          def vertex_for(v)
            @vertex_map[v.hash_code]
          end

          def to_s
            "<#{self.class.name}:#{object_id} num_vertices=#{vertices.size}>"
          end

          def inspect
            vinfo = vertices.map do |v|
              ins = in_vertices(v).map do |iv|
                "    -> #{iv}"
              end.join("\n")
              outs = out_vertices(v).map do |ov|
                "    <- #{ov}"
              end.join("\n")
              "  " + [v].tap { |content|
                content << ins if !ins.empty?
                content << outs if !outs.empty?
              }.join("\n")
            end.join("\n")
            "<#{self.class.name}:#{object_id} num_vertices=#{vertices.size} vertices=\n#{vinfo}\n>"
          end

          protected

          def basic_add_edge(u, v)
            @vertices_dict[u][:out].add(v)
            @vertices_dict[v][:in].add(u)
          end
        end
      end
    end
  end
end
