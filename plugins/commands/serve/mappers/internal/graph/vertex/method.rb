# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            # Vertex that represents a method
            class Method < Vertex
              attr_reader :callable

              def initialize(callable:)
                @callable = callable
              end

              # Since this vertex is a method to
              # execute, and requires the defined
              # input arguments, all incoming edges
              # are required
              def incoming_edges_required
                true
              end

              def hash_code
                @callable.object_id
              end

              # When a method vertex is called,
              # we execute the mapper method and
              # store the value
              def call(*args)
                # If the callable is a mapper, setup the correct
                # arguments before calling
                if @callable.respond_to?(:determine_inputs)
                  args = @callable.determine_inputs(*args)
                end
                @value = @callable.call(*args)
              end

              def to_s
                "<Vertex:Method callable=#{@callable} hash=#{hash_code}>"
              end

              def extra_weight
                if callable.respond_to?(:extra_weight)
                  return callable.extra_weight
                end
                0
              end

              def inspect
                "<#{self.class.name} callable=#{@callable} value=#{value} hash=#{hash_code}>"
              end
            end
          end
        end
      end
    end
  end
end
