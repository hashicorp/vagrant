# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    class Client
      class Guest < Client
        include CapabilityPlatform

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def detect_func
          spec = client.detect_spec(Empty.new)
          cb = proc do |args|
            client.detect(args).parent
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @return [bool]
        def detect(machine)
          run_func(machine)
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def parent_func
          spec = client.parent_spec(Empty.new)
          cb = proc do |args|
            client.parent(args).parent
          end
          [spec, cb]
        end

        # @return [String] parents
        def parent
          run_func
        end
      end
    end
  end
end
