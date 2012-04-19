require "pathname"

require "log4r"

module Vagrant
  module Config
    # This class is responsible for loading Vagrant configuration,
    # usually in the form of Vagrantfiles.
    #
    # Loading works by specifying the sources for the configuration
    # as well as the order the sources should be loaded. Configuration
    # set later always overrides those set earlier; this is how
    # configuration "scoping" is implemented.
    class Loader
      # This is an array of symbols specifying the order in which
      # configuration is loaded. For examples, see the class documentation.
      attr_accessor :load_order

      def initialize
        @logger  = Log4r::Logger.new("vagrant::config::loader")
        @sources = {}
        @proc_cache = {}
        @config_cache = {}
      end

      # Set the configuration data for the given name.
      #
      # The `name` should be a symbol and must uniquely identify the data
      # being given.
      #
      # `data` can either be a path to a Ruby Vagrantfile or a `Proc` directly.
      # `data` can also be an array of such values.
      #
      # At this point, no configuration is actually loaded. Note that calling
      # `set` multiple times with the same name will override any previously
      # set values. In this way, the last set data for a given name wins.
      def set(name, sources)
        @logger.debug("Set #{name.inspect} = #{sources.inspect}")

        # Sources should be an array
        sources = [sources] if !sources.kind_of?(Array)

        # Gather the procs for every source, since that is what we care about.
        procs = []
        sources.each do |source|
          if !@proc_cache.has_key?(source)
            # Load the procs for this source and cache them. This caching
            # avoids the issue where a file may have side effects when loading
            # and loading it multiple times causes unexpected behavior.
            @logger.debug("Populating proc cache for #{source.inspect}")
            @proc_cache[source] = procs_for_source(source)
          end

          # Add on to the array of procs we're going to use
          procs.concat(@proc_cache[source])
        end

        # Set this source by name.
        @sources[name] = procs
      end

      # This loads the configured sources in the configured order and returns
      # an actual configuration object that is ready to be used.
      def load
        @logger.debug("Loading configuration in order: #{@load_order.inspect}")

        unknown_sources = @sources.keys - @load_order
        if !unknown_sources.empty?
          # TODO: Raise exception here perhaps.
          @logger.error("Unknown config sources: #{unknown_sources.inspect}")
        end

        # This will hold our result
        result = V1.init

        @load_order.each do |key|
          next if !@sources.has_key?(key)

          @sources[key].each do |proc|
            if !@config_cache.has_key?(proc)
              @logger.debug("Loading from: #{key} (evaluating)")
              current = V1.load(proc)
              @config_cache[proc] = current
            else
              @logger.debug("Loading from: #{key} (cache)")
            end

            # Merge the configurations
            result = V1.merge(result, @config_cache[proc])
          end
        end

        @logger.debug("Configuration loaded successfully")
        result
      end

      protected

      # This returns an array of `Proc` objects for the given source.
      # The `Proc` objects returned will expect a single argument for
      # the configuration object and are expected to mutate this
      # configuration object.
      def procs_for_source(source)
        return [source] if source.is_a?(Proc)

        # Assume all string sources are actually pathnames
        source = Pathname.new(source) if source.is_a?(String)

        if source.is_a?(Pathname)
          @logger.debug("Load procs for pathname: #{source.inspect}")

          begin
            return Config.capture_configures do
              Kernel.load source
            end
          rescue SyntaxError => e
            # Report syntax errors in a nice way.
            raise Errors::VagrantfileSyntaxError, :file => e.message
          end
        end

        raise Exception, "Unknown configuration source: #{source.inspect}"
      end
    end
  end
end
