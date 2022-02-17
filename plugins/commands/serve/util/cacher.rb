module VagrantPlugins
  module CommandServe
    module Util
      class Cacher

        def initialize
          @registry = {}
        end

        def registered?(key)
          @registry.key?(key)
        end

        def register(key, value)
          @registry[key] = value
        end

        def get(key)
          @registry[key]
        end

        def unregister(key)
          @registry.delete(key)
        end

        def use(key)
          if !@registry.key?(key)
            raise KeyError,
              "No value cached with key `#{key}'"
          end

          yield @registry[key]
        end
      end
    end
  end
end
