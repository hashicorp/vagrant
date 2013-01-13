module Vagrant
  # Register components in a single location that can be queried.
  #
  # This allows certain components (such as guest systems, configuration
  # pieces, etc.) to be registered and queried, lazily.
  class Registry
    def initialize
      @items = {}
      @results_cache = {}
    end

    # Register a key with a lazy-loaded value.
    #
    # If a key with the given name already exists, it is overwritten.
    def register(key, &block)
      raise ArgumentError, "block required" if !block_given?
      @items[key] = block
    end

    # Get a value by the given key.
    #
    # This will evaluate the block given to `register` and return the
    # resulting value.
    def get(key)
      return nil if !@items.has_key?(key)
      return @results_cache[key] if @results_cache.has_key?(key)
      @results_cache[key] = @items[key].call
    end
    alias :[] :get

    # Checks if the given key is registered with the registry.
    #
    # @return [Boolean]
    def has_key?(key)
      @items.has_key?(key)
    end

    # Iterate over the keyspace.
    def each(&block)
      @items.each do |key, _|
        yield key, get(key)
      end
    end

    # Merge one registry with another and return a completely new
    # registry. Note that the result cache is completely busted, so
    # any gets on the new registry will result in a cache miss.
    def merge(other)
      self.class.new.tap do |result|
        result.merge!(self)
        result.merge!(other)
      end
    end

    # Like #{merge} but merges into self.
    def merge!(other)
      @items.merge!(other.__internal_state[:items])
      self
    end

    # Converts this registry to a hash
    def to_hash
      result = {}
      self.each do |key, value|
        result[key] = value
      end

      result
    end

    def __internal_state
      {
        :items => @items,
        :results_cache => @results_cache
      }
    end
  end
end
