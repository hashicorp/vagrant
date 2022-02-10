require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    class Client
      class Guest < Client
        include CapabilityPlatform

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

        # @return [Array<String>] parents
        def parent
          run_func
        end
      end
    end
  end
end
