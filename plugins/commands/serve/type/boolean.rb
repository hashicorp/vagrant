# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module CommandServe
    class Type
      class Boolean < Type

        def initialize(value:)
          super(value: !!value)
        end
      end
    end
  end
end
