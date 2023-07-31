# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Action
    module Builtin
      # This module enables SSHRun for server mode
      module Remote
        module SSHRun
          def _raw_ssh_exec(env, info, opts)
            # The Util::SSH package in remote mode expects to be able to
            # interact with a UI instead of raw stdin/stderr so the action
            # needs to pass that down.
            opts[:ui] = env[:ui]
            super(env, info, opts)
          end
        end
      end
    end
  end
end
