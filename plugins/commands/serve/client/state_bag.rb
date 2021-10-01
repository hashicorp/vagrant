require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      class StateBag
        prepend Util::ClientSetup
        prepend Util::HasLogger

        # @param [String]
        # @return [String]
        def get(key)
          req = SDK::StateBag::GetRequest.new(
            key: key
          )
          client.get(req).value
        end

        # @param [String]
        # @return [String, Boolean]
        def get_ok(key)
          req = SDK::StateBag::GetRequest.new(
            key: key
          )
          resp = client.get_ok(req)
          return resp.value, resp.ok
        end

        # @param [String, String]
        # @return []
        def put(key, val)
          req = SDK::StateBag::PutRequest.new(
            key: key, value: val
          )
          client.put(req)
        end

        # @param [String]
        # @return []
        def remove(key)
          req = SDK::StateBag::RemoveRequest.new(
            key: key
          )
          client.remove(req)
        end
      end
    end
  end
end
