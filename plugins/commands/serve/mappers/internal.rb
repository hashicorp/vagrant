# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      module Internal
        autoload :Graph, Vagrant.source_root.join("plugins/commands/serve/mappers/internal/graph").to_s
      end
    end
  end
end
