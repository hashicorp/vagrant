module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            # Vertex that represents a method
            class Method < Vertex
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

              def inspect
                "<Vertex:Method:#{object_id} hash=#{hash_code} callable=#{@callable} value=#{value}>"
              end
            end
          end
        end
      end
    end
  end
end
