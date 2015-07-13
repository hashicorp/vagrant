module Vagrant
  # This module enables a class to host capabilities. Prior to being able
  # to use any capabilities, the `initialize_capabilities!` method must be
  # called.
  #
  # Capabilities allow small pieces of functionality to be plugged in using
  # the Vagrant plugin model. Capabilities even allow for a certain amount
  # of inheritence, where only a subset of capabilities may be implemented but
  # a parent implements the rest.
  #
  # Capabilities are used heavily in Vagrant for host/guest interactions. For
  # example, "mount_nfs_folder" is a guest-OS specific operation, so capabilities
  # defer these operations to the guest.
  module CapabilityHost
    # Initializes the capability system by detecting the proper capability
    # host to execute on and building the chain of capabilities to execute.
    #
    # @param [Symbol] host The host to use for the capabilities, or nil if
    #   we should auto-detect it.
    # @param [Hash<Symbol, Array<Class, Symbol>>] hosts Potential capability
    #   hosts. The key is the name of the host, value[0] is a class that
    #   implements `#detect?` and value[1] is a parent host (if any).
    # @param [Hash<Symbol, Hash<Symbol, Class>>] capabilities The capabilities
    #   that are supported. The key is the host of the capability. Within that
    #   is a hash where the key is the name of the capability and the value
    #   is the class/module implementing it.
    def initialize_capabilities!(host, hosts, capabilities, *args)
      @cap_logger = Log4r::Logger.new(
        "vagrant::capability_host::#{self.class.to_s.downcase}")

      if host && !hosts[host]
        raise Errors::CapabilityHostExplicitNotDetected, value: host.to_s
      end

      if !host
        host = autodetect_capability_host(hosts, *args) if !host
        raise Errors::CapabilityHostNotDetected if !host
      end

      if !hosts[host]
        # This should never happen because the autodetect above uses the
        # hosts hash to look up hosts. And if an explicit host is specified,
        # we do another check higher up.
        raise "Internal error. Host not found: #{host}"
      end

      name      = host
      host_info = hosts[name]
      host      = host_info[0].new
      chain     = []
      chain << [name, host]

      # Build the proper chain of parents if there are any.
      # This allows us to do "inheritance" of capabilities later
      if host_info[1]
        parent_name = host_info[1]
        parent_info = hosts[parent_name]
        while parent_info
          chain << [parent_name, parent_info[0].new]
          parent_name = parent_info[1]
          parent_info = hosts[parent_name]
        end
      end

      @cap_host_chain = chain
      @cap_args       = args
      @cap_caps       = capabilities
      true
    end

    # Returns the chain of hosts that will be checked for capabilities.
    #
    # @return [Array<Array<Symbol, Class>>]
    def capability_host_chain
      @cap_host_chain
    end

    # Tests whether the given capability is possible.
    #
    # @param [Symbol] cap_name Capability name
    # @return [Boolean]
    def capability?(cap_name)
      !capability_module(cap_name.to_sym).nil?
    end

    # Executes the capability with the given name, optionally passing more
    # arguments onwards to the capability. If the capability returns a value,
    # it will be returned.
    #
    # @param [Symbol] cap_name Name of the capability
    def capability(cap_name, *args)
      cap_mod = capability_module(cap_name.to_sym)
      if !cap_mod
        raise Errors::CapabilityNotFound,
          cap:  cap_name.to_s,
          host: @cap_host_chain[0][0].to_s
      end

      cap_method = nil
      begin
        cap_method = cap_mod.method(cap_name)
      rescue NameError
        raise Errors::CapabilityInvalid,
          cap: cap_name.to_s,
          host: @cap_host_chain[0][0].to_s
      end

      args = @cap_args + args
      @cap_logger.info(
        "Execute capability: #{cap_name} #{args.inspect} (#{@cap_host_chain[0][0]})")
      cap_method.call(*args)
    end

    protected

    def autodetect_capability_host(hosts, *args)
      @cap_logger.info("Autodetecting host type for #{args.inspect}")

      # Get the mapping of hosts with the most parents. We start searching
      # with the hosts with the most parents first.
      parent_count = {}
      hosts.each do |name, parts|
        parent_count[name] = 0

        parent = parts[1]
        while parent
          parent_count[name] += 1
          parent = hosts[parent]
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

      sorted_counts = parent_count_to_hosts.keys.sort.reverse
      sorted_counts.each do |count|
        parent_count_to_hosts[count].each do |name|
          @cap_logger.debug("Trying: #{name}")
          host_info = hosts[name]
          host      = host_info[0].new

          if host.detect?(*args)
            @cap_logger.info("Detected: #{name}!")
            return name
          end
        end
      end

      return nil
    end

    # Returns the registered module for a capability with the given name.
    #
    # @param [Symbol] cap_name
    # @return [Module]
    def capability_module(cap_name)
      @cap_logger.debug("Searching for cap: #{cap_name}")
      @cap_host_chain.each do |host_name, host|
        @cap_logger.debug("Checking in: #{host_name}")
        caps = @cap_caps[host_name]

        if caps && caps.key?(cap_name)
          @cap_logger.debug("Found cap: #{cap_name} in #{host_name}")
          return caps[cap_name]
        end
      end

      nil
    end
  end
end
