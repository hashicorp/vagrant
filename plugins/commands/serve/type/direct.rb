# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module CommandServe
    class Type
      class Direct < Type
        attr_accessor :args

        def initialize(arguments: nil, value: nil)
          value = arguments if value.nil?
          super(value: value)
          @args = value
        end

        def arguments
          @args
        end
      end
    end
  end
end
