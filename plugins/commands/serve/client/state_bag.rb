# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class StateBag < Client
        # @param [String]
        # @return [String]
        def get(key)
          req = SDK::StateBag::GetRequest.new(
            key: key
          )
          client.get(req).value
        end
        alias_method :[], :get

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
        alias_method :[]=, :put

        # @param [String]
        # @return []
        def remove(key)
          req = SDK::StateBag::RemoveRequest.new(
            key: key
          )
          client.remove(req)
        end
        alias_method :delete, :remove

      end
    end
  end
end
