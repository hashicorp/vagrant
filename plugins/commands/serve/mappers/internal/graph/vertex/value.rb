# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            # Vertex that represents a value
            class Value < Vertex
              # @return [Class] hash code for value
              def hash_code
                value.class
              end

              # @return [Class] type of the value
              def type
                value.class
              end

              def to_s
                "<Vertex:Value type=#{type} hash=#{hash_code}>"
              end

              def inspect
                "<#{self.class.name} type=#{type} value=#{value} hash=#{hash_code}>"
              end
            end
          end
        end
      end
    end
  end
end
