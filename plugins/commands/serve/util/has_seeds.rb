module VagrantPlugins
  module CommandServe
    module Util
      module HasSeeds
        # Provides seed value registration.
        module Service
          def seed(req, ctx)
            logger.info("ruby side received seed through service - #{req.inspect}")
            @seeds = req
            Empty.new
          end

          def seeds(req, ctx)
            logger.info("ruby side received seed request through service - #{@seeds.inspect}")
            return SDK::Args::Seeds.new if @seeds.nil?
            @seeds
          end
        end

        # Provides seed access.
        module Client
          def seed(*args)
            raise NotImplementedError,
              "Seeding is currently not supported via Ruby client"
          end

          def seeds
            client.seeds(Empty.new)
          end
        end
      end
    end
  end
end
