# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestPld
    module Cap
      class Flavor
        def self.flavor(machine)
          return :pld
        end
      end
    end
  end
end
