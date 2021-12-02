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
        def parents
          logger.debug("getting parents")
          req = SDK::FuncSpec::Args.new(
            args: []
          )
          res = client.parents(req)
          logger.debug("got parents #{res}")
          res.parents
        end
      end
    end
  end
end
