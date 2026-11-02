# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        class Graph
          class Vertex
            # Vertex that represents an input value
            # for a method
            class Input < Vertex
              attr_reader :type
              attr_reader :name

              def initialize(type:, name: nil, origin_restricted: false)
                @type = type
                @name = name
                @origin_value_only = !!origin_restricted
              end

              def origin_value_only?
                @origin_value_only
              end

              # When an input Vertex is called,
              # we simply set the value for use
              def call(arg)
                @value = arg
              end

              def to_s
                info = {
                  name: name,
                  type: type,
                  hash: hash_code,
                }.compact.map { |k, v|
                  "#{k} = #{v}"
                }.join(" ")
                "<Vertex:Input #{info}>"
              end

              def inspect
                info = {
                  name: name,
                  type: type,
                  value: value,
                  hash: hash_code,
                }.map { |k, v|
                  "#{k} = #{v}"
                }.join(" ")
                "<#{self.class.name} #{info}>"
              end
            end
          end
        end
      end
    end
  end
end
