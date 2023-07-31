# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module HostBSD
    module Cap
      class Path
        def self.resolve_host_path(env, path)
          path
        end
      end
    end
  end
end
