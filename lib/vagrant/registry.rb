module Vagrant
  # Register components in a single location that can be queried.
  #
  # This allows certain components (such as guest systems, configuration
  # pieces, etc.) to be registered and queried.
  class Registry
    def initialize
      @actions = {}
      @results_cache = {}
    end

    # Register a callable by key.
    #
    # The callable should be given in a block which will be lazily evaluated
    # when the action is needed.
    #
    # If an action by the given name already exists then it will be
    # overwritten.
    def register(key, value=nil, &block)
      block = lambda { value } if value
      @actions[key] = block
    end

    # Get an action by the given key.
    #
    # This will evaluate the block given to `register` and return the resulting
    # action stack.
    def get(key)
      return nil if !@actions.has_key?(key)
      return @results_cache[key] if @results_cache.has_key?(key)
      @results_cache[key] = @actions[key].call
    end
    alias :[] :get

    # Checks if the given key is registered with the registry.
    #
    # @return [Boolean]
    def has_key?(key)
      @actions.has_key?(key)
    end

    # Iterate over the keyspace.
    def each(&block)
      @actions.each do |key, _|
        yield key, get(key)
      end
    end

    # Converts this registry to a hash
    def to_hash
      result = {}
      self.each do |key, value|
        result[key] = value
      end

      result
    end
  end
end
