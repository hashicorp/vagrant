module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          # Wrapper around a vertex and used within the
          # graph to allow weighting edges for path
          # preference. All vertices within a graph are
          # WeightedVertex instances. Paths with the
          # lowest weights are preferred.
          class WeightedVertex
            attr_reader :hash_code
            attr_reader :weight

            def initialize(code:, weight:)
              @hash_code = code
              if !weight.is_a?(Integer)
                raise TypeError,
                  "Expected `Integer' type for weight, got `#{weight.class}'"
              end
              @weight = weight
            end
          end
        end
      end
    end
  end
end
