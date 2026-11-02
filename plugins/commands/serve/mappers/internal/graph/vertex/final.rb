# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            # Vertex that represents an output of
            # a method
            class Final < Vertex
              attr_reader :type

              def initialize(type:)
                @type = type
              end

              # When an output Vertex is called,
              # we simply set the value for use
              def call(arg)
                @value = arg
              end

              def to_s
                "<Vertex:Final type=#{type} hash=#{hash_code}>"
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
