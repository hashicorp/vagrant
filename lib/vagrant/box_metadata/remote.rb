# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
      def initialize(io, url: nil, client: nil)
        @logger = Log4r::Logger.new("vagrant::box")

        if !client.nil? 
          # Use client if available
          @client = client
        else
          # If client is not available, then try to load from url
          if url.nil?
            raise ArgumentError,
              "Metadata URL is required for `#{self.class.name}' if a client is not provided"
          end
          @client = Vagrant.plugin("2").remote_manager.core_plugin_manager.get_plugin("boxmetadata")
          @client.load_metadata(url)
        end
        @name = @client.name
      end

      def version(version, **opts)
        providers = nil
        providers = Array(opts[:provider]) || []

        v = @client.version(version, providers)
        Version.new(v, ver: v[:version], client: @client)
      end

      def versions(**opts)
        provider = nil
        provider = opts[:provider].to_sym if opts[:provider]
        v = @client.list_versions(provider)
        # Sort so the last element of the list is the latest version. 
        v.sort.map(&:to_s)
      end

      class Version
        attr_accessor :version

        def initialize(raw=nil, ver: nil, client: nil)
          return if raw.nil?
          @logger = Log4r::Logger.new("vagrant::box::version")

          @version = ver
          if client.nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}'"
          end
          @client = client
        end

        def provider(name)
          p = @client.provider(@version, name)
          Provider.new(p, client: @client)
        end

        def providers
          @client.list_providers(@version)
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
