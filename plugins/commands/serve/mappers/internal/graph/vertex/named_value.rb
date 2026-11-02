# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            class NamedValue < Value
              # @return [String] name of value
              attr_reader :name

              def initialize(name:, value:)
                super(value: value)
                @name = name.to_s
              end

              def hash_code
                "#{name}-#{value.class}"
              end
            end
          end
        end
      end
    end
  end
end
