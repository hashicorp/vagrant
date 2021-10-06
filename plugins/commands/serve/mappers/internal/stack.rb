module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        # Simple stack implementation
        class Stack
          def initialize
            @data = []
            @m = Mutex.new
          end

          def include?(v)
            @m.synchronize do
              @data.include?(v)
            end
          end

          def pop
            @m.synchronize do
              @data.pop
            end
          end

          def push(v)
            @m.synchronize do
              @data.push(v)
            end
          end

          def size
            @m.synchronize do
              @data.size
            end
          end

          def values
            @m.synchronize do
              @data.dup
            end
          end
        end
      end
    end
  end
end
