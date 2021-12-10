require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      class Guest
        prepend Util::ClientSetup
        prepend Util::HasLogger

        include CapabilityPlatform
        include Util::HasSeeds::Client

        # @return [<String>] parents
        def parent
          req = SDK::FuncSpec::Args.new(
            args: []
          )
          res = client.parent(req)
          res.parent
        end
      end
    end
  end
end
