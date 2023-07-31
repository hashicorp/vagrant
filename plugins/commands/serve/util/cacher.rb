# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      # Simple container for caching values
      class Cacher

        include HasLogger

        def initialize
          @registry = {}
        end

        def clear
          @registry = {}
        end

        # Check if the given key is currently registered
        #
        # @param key [Object] Generally String or Symbol
        # @return [Boolean]
        def registered?(key)
          @registry.key?(key)
        end

        # Register a new value under given key
        #
        # @param key [Object] Generally String or Symbol
        # @param value [Object] Value to register
        # @return [Object] value
        def register(key, value)
          logger.trace("cache register #{key} = #{value}")
          @registry[key] = value
        end

        # Get registered value
        #
        # @param key [Object] Generally String or Symbol
        # @return [Object] value
        # @raises [KeyError]
        def get(key)
          if !@registry.key?(key)
            raise KeyError,
              "Unknown cache key #{key.inspect}"
          end
          @registry[key]
        end

        # Remove item from the cache
        #
        # @param key [Object] Generally String or Symbol
        # @return [Object] value or nil
        def unregister(key)
          @registry.delete(key)
        end

        # Yield value to given block
        #
        # @param key [Object] Generally String or Symbol
        # @yieldparam [Object] value
        def use(key)
          if !@registry.key?(key)
            raise KeyError,
              "Unknown cache key #{key.inspect}"
          end

          yield @registry[key]
        end

        # Generate a key with given arguments
        #
        # @return [String]
        def key(*args)
          args.map { |v|
            if v.is_a?(Class)
              v.name
            elsif v.respond_to?(:client)
              v.client.respond_to?(:resource_id) ?
                v.client.resource_id :
                v.client.to_proto.to_s
            else
              v.to_s
            end
          }.sort.join("-")
        end
      end
    end
  end
end
