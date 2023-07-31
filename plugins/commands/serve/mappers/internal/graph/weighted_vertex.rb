# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "delegate"
require "forwardable"

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
          class WeightedVertex < SimpleDelegator

            # Force the delegator to properly look like the
            # vertex its decorating
            extend Forwardable
            def_delegators :__getobj__, :is_a?, :kind_of?, :class

            attr_reader :weight

            def initialize(vertex, weight:)
              if !vertex.is_a?(Vertex)
                raise TypeError,
                  "Expected `Vertex' type, got `#{vertex.class}'"
              end
              self.weight = weight
              super(vertex)
            end

            def weight=(w)
              if !w.is_a?(Integer)
                raise TypeError,
                  "Expected `Integer' type for weight, got `#{w.class}'"
              end
              @weight = w
            end
          end
        end
      end
    end
  end
end
