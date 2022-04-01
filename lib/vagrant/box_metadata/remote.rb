module Vagrant
  class BoxMetadata
    # This module enables the BoxMetadata for server mode
    module Remote

      # Add an attribute reader for the client
      # when applied to the BoxMetadata class
      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      attr_accessor :name
      attr_accessor :description

      # @param [IO] io An IO object to read the metadata from.
      def initialize(io, url: nil)
        @logger = Log4r::Logger.new("vagrant::box")

        if url.nil?
          raise ArgumentError,
            "Metadata URL is required for `#{self.class.name}'"
        end
        @client = Vagrant.plugin("2").remote_manager.core_plugin_manager.get_plugin("boxmetadata")
        @client.load_metadata(url)
      end

      def version(version, **opts)
        providers = nil
        providers = Array(opts[:provider]).map(&:to_sym) if opts[:provider]

        v = @client.version(version, providers)
        @logger.debug("found version for #{version}, #{providers}: #{v}")
        Version.new(v, ver: v[:version], client: @client)
      end

      def versions(**opts)
        provider = nil
        provider = opts[:provider].to_sym if opts[:provider]
        @client.versions(provider)
      end

      class Version
        attr_accessor :version

        def initialize(raw=nil, ver: nil, client: nil)
          return if raw.nil?
          @logger = Log4r::Logger.new("vagrant::box::version")

          @logger.debug("creating version with ver #{ver} and client #{client}")
          @version = ver
          if client.nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}'"
          end
          @client = client
        end

        def provider(name)
          @logger.debug("searching for provider with ver #{@version}")
          p = @client.provider(@version, name)
          Provider.new(p, client: @client)
        end

        def providers
          @logger.debug("searching for providers with ver #{@version}")
          @client.providers(@version)
        end

        class Provider
          attr_accessor :name
          attr_accessor :url
          attr_accessor :checksum
          attr_accessor :checksum_type

          def initialize(raw, client: nil)
            @name = raw[:name]
            @url  = raw[:url]
            @checksum = raw[:checksum]
            @checksum_type = raw[:checksum_type]
            if client.nil?
              raise ArgumentError,
                "Remote client is required for `#{self.class.name}'"
            end
            @client = client
          end
        end
      end
    end
  end
end
