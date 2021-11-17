require "monitor"

module VagrantPlugins
  module CommandServe
    module Util
      class Cacher
        include MonitorMixin

        class Entry
          include MonitorMixin
          attr_reader :value

          def initialize(value)
            super()
            @value = value
          end
        end

        def initialize
          super()
          @registry = {}
        end

        def registered?(key)
          synchronize { @registry.key?(key) }
        end

        def []=(key, value)
          entry = Entry.new(value)
          synchronize { @registry[key] = entry }
        end

        def [](key)
          synchronize { @registry[key]&.value }
        end

        def delete(key)
          entry = @registry[key]
          return if entry.nil?
          entry.synchronize do
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

          entry.synchronize do
            yield entry.value
          end
        end
      end
    end
  end
end
