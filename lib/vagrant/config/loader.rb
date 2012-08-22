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

      # Initializes a configuration loader.
      #
      # @param [Registry] versions A registry of the available versions and
      #   their associated loaders.
      # @param [Array] version_order An array of the order of the versions
      #   in the registry. This is used to determine if upgrades are
      #   necessary. Additionally, the last version in this order is always
      #   considered the "current" version.
      def initialize(versions, version_order)
        @logger        = Log4r::Logger.new("vagrant::config::loader")
        @config_cache  = {}
        @proc_cache    = {}
        @sources       = {}
        @versions      = versions
        @version_order = version_order
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

        # Get the current version config class to use
        current_version      = @version_order.last
        current_config_klass = @versions.get(current_version)

        # This will hold our result
        result = current_config_klass.init

        @load_order.each do |key|
          next if !@sources.has_key?(key)

          @sources[key].each do |version, proc|
            if !@config_cache.has_key?(proc)
              @logger.debug("Loading from: #{key} (evaluating)")

              # Get the proper version loader for this version and load
              version_loader = @versions.get(version)
              version_config = version_loader.load(proc)

              # If this version is not the current version, then we need
              # to upgrade to the latest version.
              if version != current_version
                @logger.debug("Upgrading config from version #{version} to #{current_version}")
                version_index = @version_order.index(version)
                current_index = @version_order.index(current_version)

                (version_index + 1).upto(current_index) do |index|
                  next_version = @version_order[index]
                  @logger.debug("Upgrading config to version #{next_version}")

                  # Get the loader of this version and ask it to upgrade
                  loader = @versions.get(next_version)
                  upgrade_result = loader.upgrade(version_config)

                  # XXX: Do something with the warning/error messages
                  warnings = upgrade_result[1]
                  errors   = upgrade_result[2]
                  @logger.debug("Upgraded to version #{next_version} with " +
                                "#{warnings.length} warnings and " +
                                "#{errors.length} errors")

                  # Store the new upgraded version
                  version_config = upgrade_result[0]
                end
              end

              # Cache the results for this proc
              @config_cache[proc] = version_config
            else
              @logger.debug("Loading from: #{key} (cache)")
            end

            # Merge the configurations
            result = current_config_klass.merge(result, @config_cache[proc])
          end
        end

        @logger.debug("Configuration loaded successfully, finalizing and returning")
        current_config_klass.finalize(result)
      end

      protected

      # This returns an array of `Proc` objects for the given source.
      # The `Proc` objects returned will expect a single argument for
      # the configuration object and are expected to mutate this
      # configuration object.
      def procs_for_source(source)
        # Convert all pathnames to strings so we just have their path
        source = source.to_s if source.is_a?(Pathname)

        if source.is_a?(Array)
          # An array must be formatted as [version, proc], so verify
          # that and then return it
          raise ArgumentError, "String source must have format [version, proc]" if source.length != 2

          # Return it as an array since we're expected to return an array
          # of [version, proc] pairs, but an array source only has one.
          return [source]
        elsif source.is_a?(String)
          # Strings are considered paths, so load them
          return procs_for_path(source)
        else
          raise ArgumentError, "Unknown configuration source: #{source.inspect}"
        end
      end

      # This returns an array of `Proc` objects for the given path source.
      #
      # @param [String] path Path to the file which contains the proper
      #   `Vagrant.configure` calls.
      # @return [Array<Proc>]
      def procs_for_path(path)
        @logger.debug("Load procs for pathname: #{path}")

        begin
          return Config.capture_configures do
            Kernel.load path
          end
        rescue SyntaxError => e
          # Report syntax errors in a nice way.
          raise Errors::VagrantfileSyntaxError, :file => e.message
        end
       end
    end
  end
end
