require "mutex_m"

module VagrantPlugins
  module CommandServe
    module Util
      class Cacher
        include Mutex_m

        class Entry
          include Mutex_m
          attr_reader :value

          def initialize(value)
            super()
            @value = value
          end

          def value
            raise "Entry must be locked to access value" if !mu_locked?
            @value
          end
        end

        def initialize
          super()
          @registry = {}
        end

        def registered?(key)
          mu_synchronize { @registry.key?(key) }
        end

        def []=(key, value)
          entry = Entry.new(value)
          mu_synchronize { @registry[key] = entry }
        end

        def [](key)
          mu_synchronize { @registry[key] }
        end

        def delete(key)
          entry = @registry[key]
          return if entry.nil?
          entry.mu_synchronize do
            value = entry.value
            @registry.delete(key)
            value
          end
        end

        # TODO: need to add a lock/unlock for an entry so
        #       we can "check it out" for use during a request
        #       and then return it without needing to deal with
        #       block wrapping to maintain the lock.
        def use(key)
          entry = self[key]
          if entry.nil?
            raise KeyError,
              "No value cached with key `#{key}'"
          end

          entry.mu_synchronize do
            yield entry.value
          end
        end

        def checkout(key, wait: false)
          entry = self[key]
          if entry.nil?
            raise KeyError,
              "No value cached with key `#{key}'"
          end
          if wait
            entry.mu_lock
            entry.value
          else
            if !entry.mu_try_lock
              raise LockError,
                "Failed to lock cached entry with key `#{key}'"
            end
            entry.value
          end
        end

        def checkin(key)
          entry = self[key]
          return if entry.nil?
          entry.mu_unlock
          nil
        end
      end
    end
  end
end
