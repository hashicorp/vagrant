# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

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
