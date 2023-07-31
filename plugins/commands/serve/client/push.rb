# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class Push < Client
        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def push_func
          spec = client.push_spec(Empty.new)
          cb = proc do |args|
            client.push(args)
          end
          [spec, cb]
        end

        # Execute push
        def push
          run_func
        end
      end
    end
  end
end
