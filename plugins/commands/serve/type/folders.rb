# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Type
      class Folders < Type

        def initialize(value:)
          super(value: value)
        end
      end
    end
  end
end
