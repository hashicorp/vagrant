module VagrantPlugins
  module CommandServe
    module Util
      class Cacher

        class Entry
          attr_reader :value
          attr_reader :m

          def initialize(value)
            @value = value
            @m = Mutex.new
          end
        end

        def initialize
          @m = Mutex.new
          @registry = {}
        end

        def registered?(key)
          @registry.key?(key)
        end

        def []=(key, value)
          entry = Entry.new(value)
          @m.synchronize { @registry[key] = entry }
        end

        def [](key)
          @m.synchronize { @registry[key]&.value }
        end

        def delete(key)
          entry = @registry[key]
          return if entry.nil?
          entry.m.synchronize do
            value = @registry[key].value
            @registry.delete(key)
            value
          end
        end

        # TODO: need to add a lock/unlock for an entry so
        #       we can "check it out" for use during a request
        #       and then return it without needing to deal with
        #       block wrapping to maintain the lock.
        def use(key)
          entry = @registry[key]
          if entry.nil?
            raise KeyError,
              "No value cached with key `#{key}'"
          end

          entry.m.synchronize do
            yield entry.value
          end
        end
      end
    end
  end
end
