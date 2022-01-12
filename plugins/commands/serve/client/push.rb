module VagrantPlugins
  module CommandServe
    module Client
      class Push
        prepend Util::ClientSetup
        prepend Util::HasLogger

        include Util::HasSeeds::Client

        def push
          logger.debug("doing push")
          req = SDK::FuncSpec::Args.new(args: seed_protos)
          res = client.push(req)
          logger.debug("got response #{res}")
          res
        end
      end
    end
  end
end
