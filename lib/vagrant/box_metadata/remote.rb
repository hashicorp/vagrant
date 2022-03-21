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
      def initialize(io, client: nil)
        @logger = Log4r::Logger.new("vagrant::box")

        if client.nil?
          raise ArgumentError,
            "Remote client is required for `#{self.class.name}'"
        end
        @client = client
      end

      def version(version, **opts)
        v = client.version(version, opts[:provider])
        Version.new(v, ver: v["version"], client: @client)
      end

      def versions(**opts)
        provider = nil
        provider = opts[:provider].to_sym if opts[:provider]
        client.versions(provider)
      end

      class Version
        attr_accessor :version

        def initialize(raw=nil, ver: nil, client: nil)
          return if raw.nil?

          @version = ver
          if client.nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}'"
          end
          @client = client
        end

        def provider(name)
          p = client.provider(@version, name)
          Provider.new(p, @client)
        end

        def providers
          client.providers(@version)
        end

        class Provider
          attr_accessor :name
          attr_accessor :url
          attr_accessor :checksum
          attr_accessor :checksum_type

          def initialize(raw, client: nil)
            @name = raw["name"]
            @url  = raw["url"]
            @checksum = raw["checksum"]
            @checksum_type = raw["checksum_type"]
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
