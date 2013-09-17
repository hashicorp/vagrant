require 'log4r'

module Vagrant
  # TODO: * Documentation
  #       * "Implement" HostNotDetected, HostCapabilityInvalid, HostCapabilityNotFound
  #       * Handle manually configured host classes
  #       * Check if there'll be breaking changes
  #       * Pass in Vagrant::Environment as argument to capabilities
  class Host
    attr_reader :chain

    # The name of the host OS. This is available after {#detect!} is
    # called.
    #
    # @return [Symbol]
    attr_reader :name

    def initialize(config, hosts, capabilities)
      @logger       = Log4r::Logger.new("vagrant::host")
      @config       = config
      @capabilities = capabilities
      @chain        = []
      @hosts        = hosts
      @name         = nil
    end

    # This will detect the proper host OS and will set up the class to actually
    # execute capabilities.
    def detect!
      @logger.info("Detecting host")

      # Get the mapping of hosts with the most parents. We start searching
      # with the hosts with the most parents first.
      parent_count = {}
      @hosts.each do |name, parts|
        parent_count[name] = 0

        parent = parts[1]
        while parent
          parent_count[name] += 1
          parent = @hosts[parent]
          parent = parent[1] if parent
        end
      end

      # Now swap around the mapping so that it is a mapping of
      # count to the actual list of host names
      parent_count_to_hosts = {}
      parent_count.each do |name, count|
        parent_count_to_hosts[count] ||= []
        parent_count_to_hosts[count] << name
      end

      catch(:host_os) do
        sorted_counts = parent_count_to_hosts.keys.sort.reverse
        sorted_counts.each do |count|
          parent_count_to_hosts[count].each do |name|
            @logger.debug("Trying: #{name}")
            host_info = @hosts[name]
            host      = host_info[0].new

            # If a specific host was specified, then attempt to use that
            # host no matter what. Otherwise, only use it if it was detected.
            use_this_host = false
            #if @config.vm.host.nil?
              use_this_host = host.detect?
            #else
            #  use_this_host = @config.vm.host.to_sym == name.to_sym
            #end

            if use_this_host
              @logger.info("Detected: #{name}!")
              @chain << [name, host]
              @name = name

              # Build the proper chain of parents if there are any.
              # This allows us to do "inheritance" of capabilities later
              if host_info[1]
                parent_name = host_info[1]
                parent_info = @hosts[parent_name]
                while parent_info
                  @chain << [parent_name, parent_info[0].new]
                  parent_name = parent_info[1]
                  parent_info = @hosts[parent_name]
                end
              end

              @logger.info("Full host chain: #{@chain.inspect}")

              # Exit the search
              throw :host_os
            end
          end
        end
      end

      # We shouldn't reach this point. Ideally we would detect
      # all operating systems.
      raise Errors::HostNotDetected if @chain.empty?
    end

    # Tests whether the guest has the named capability.
    #
    # @return [Boolean]
    def capability?(cap_name)
      !capability_module(cap_name.to_sym).nil?
    end

    # Executes the capability with the given name, optionally passing
    # more arguments onwards to the capability.
    def capability(cap_name, *args)
      @logger.info("Execute capability: #{cap_name} (#{@chain[0][0]})")
      cap_mod = capability_module(cap_name.to_sym)
      if !cap_mod
        raise Errors::HostCapabilityNotFound,
          :cap  => cap_name.to_s,
          :host => @chain[0][0].to_s
      end

      cap_method = nil
      begin
        cap_method = cap_mod.method(cap_name)
      rescue NameError
        raise Errors::HostCapabilityInvalid,
          :cap  => cap_name.to_s,
          :host => @chain[0][0].to_s
      end

      cap_method.call(nil, *args)
    end

    protected

    # Returns the registered module for a capability with the given name.
    #
    # @param [Symbol] cap_name
    # @return [Module]
    def capability_module(cap_name)
      @logger.debug("Searching for cap: #{cap_name}")
      @chain.each do |host_name, host|
        @logger.debug("Checking in: #{host_name}")
        caps = @capabilities[host_name]

        if caps && caps.has_key?(cap_name)
          @logger.debug("Found cap: #{cap_name} in #{host_name}")
          return caps[cap_name]
        end
      end

      nil
    end
  end
end
