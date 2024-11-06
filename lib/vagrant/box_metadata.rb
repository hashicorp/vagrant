# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require "json"

module Vagrant
  # BoxMetadata represents metadata about a box, including the name
  # it should have, a description of it, the versions it has, and
  # more.
  class BoxMetadata

    autoload :Remote, "vagrant/box_metadata/remote"

    # The name that the box should be if it is added.
    #
    # @return [String]
    attr_accessor :name

    # The long-form human-readable description of a box.
    #
    # @return [String]
    attr_accessor :description

    # Loads the metadata associated with the box from the given
    # IO.
    #
    # @param [IO] io An IO object to read the metadata from.
    def initialize(io, **_)
      begin
        @raw = JSON.load(io)
      rescue JSON::ParserError => e
        raise Errors::BoxMetadataMalformed,
          error: e.to_s
      end

      @raw ||= {}
      @name = @raw["name"]
      @description = @raw["description"]
      @version_map = (@raw["versions"] || []).map do |v|
        begin
          [Gem::Version.new(v["version"]), Version.new(v)]
        rescue ArgumentError
          raise Errors::BoxMetadataMalformedVersion,
            version: v["version"].to_s
        end
      end
      @version_map = Hash[@version_map]
    end

    # Returns data about a single version that is included in this
    # metadata.
    #
    # @param [String] version The version to return, this can also
    #   be a constraint.
    # @return [Version] The matching version or nil if a matching
    #   version was not found.
    def version(version, **opts)
      requirements = version.split(",").map do |v|
        Gem::Requirement.new(v.strip)
      end

      providers = nil
      providers = Array(opts[:provider]).map(&:to_sym) if opts[:provider]
      # NOTE: The :auto value is not expanded here since no architecture
      #       value comparisons are being done within this method
      architecture = opts.fetch(:architecture, :auto)

      @version_map.keys.sort.reverse.each do |v|
        next if !requirements.all? { |r| r.satisfied_by?(v) }
        version = @version_map[v]
        valid_providers = version.providers

        # If filtering by provider(s), apply filter
        valid_providers &= providers if providers

        # Skip if no valid providers are found
        next if valid_providers.empty?

        # Skip if no valid provider includes support
        # the desired architecture
        next if architecture && valid_providers.none? { |p|
          version.provider(p, architecture)
        }

        return version
      end

      nil
    end

    # Returns all the versions supported by this metadata. These
    # versions are sorted so the last element of the list is the
    # latest version. Optionally filter versions by a matching
    # provider.
    #
    # @return[Array<String>]
    def versions(**opts)
      architecture = opts[:architecture]
      provider = opts[:provider].to_sym if opts[:provider]

      # Return full version list if no filters provided
      if provider.nil? && architecture.nil?
        return @version_map.keys.sort.map(&:to_s)
      end

      # If a specific provider is not provided, filter
      # only on architecture
      if provider.nil?
        return @version_map.select { |_, version|
          !version.providers(architecture).empty?
        }.keys.sort.map(&:to_s)
      end

      @version_map.select { |_, version|
        version.provider(provider, architecture)
      }.keys.sort.map(&:to_s)
    end

    # Represents a single version within the metadata.
    class Version
      # The version that this Version object represents.
      #
      # @return [String]
      attr_accessor :version

      def initialize(raw=nil, **_)
        return if !raw

        @version = raw["version"]
        @providers = raw.fetch("providers", []).map do |data|
          Provider.new(data)
        end
        @provider_map = @providers.group_by(&:name)
        @provider_map = Util::HashWithIndifferentAccess.new(@provider_map)
      end

      # Returns a [Provider] for the given name, or nil if it isn't
      # supported by this version.
      def provider(name, architecture=nil)
        name = name.to_sym
        arch_name = architecture
        arch_name = Util::Platform.architecture if arch_name == :auto
        arch_name = arch_name.to_s if arch_name

        # If the provider doesn't exist in the map, return immediately
        return if !@provider_map.key?(name)

        # If the arch_name value is set, filter based
        # on architecture and return match if found. If
        # no match is found and architecture wasn't automatically
        # detected, return nil as an explicit match is
        # being requested
        if arch_name
          match = @provider_map[name].detect do |p|
            p.architecture == arch_name
          end

          return match if match || architecture != :auto
        end

        # If the passed architecture value was :auto and no explicit
        # match for the architecture was found, check for a provider
        # that is flagged as the default architecture, and has an
        # architecture value of "unknown"
        #
        # NOTE: This preserves expected behavior with legacy boxes
        if architecture == :auto
          match = @provider_map[name].detect do |p|
            p.architecture == "unknown" &&
              p.default_architecture
          end

          return match if match
        end

        # If the architecture value is set to nil, then just return
        # whatever is defined as the default architecture
        if architecture.nil?
          match = @provider_map[name].detect(&:default_architecture)

          return match if match
        end

        # The metadata consumed may not include architecture information,
        # in which case the match would just be the single provider
        # defined within the provider map for the name
        if @provider_map[name].size == 1 && !@provider_map[name].first.architecture_support?
          return @provider_map[name].first
        end

        # Otherwise, there is no match
        nil
      end

      # Returns the providers that are available for this version
      # of the box.
      #
      # @return [Array<Symbol>]
      def providers(architecture=nil)
        return @provider_map.keys.map(&:to_sym) if architecture.nil?

        @provider_map.keys.find_all { |k|
          provider(k, architecture)
        }.map(&:to_sym)
      end
    end

    # Provider represents a single provider-specific box available
    # for a version for a box.
    class Provider
      # The name of the provider.
      #
      # @return [String]
      attr_accessor :name

      # The URL of the box.
      #
      # @return [String]
      attr_accessor :url

      # The checksum value for this box, if any.
      #
      # @return [String]
      attr_accessor :checksum

      # The type of checksum (if any) associated with this provider.
      #
      # @return [String]
      attr_accessor :checksum_type

      # The architecture of the box
      #
      # @return [String]
      attr_accessor :architecture

      # Marked as the default architecture
      #
      # @return [Boolean, NilClass]
      attr_accessor :default_architecture

      def initialize(raw, **_)
        @name = raw["name"]
        @url  = raw["url"]
        @checksum = raw["checksum"]
        @checksum_type = raw["checksum_type"]
        @architecture = raw["architecture"]
        @default_architecture = raw["default_architecture"]
      end

      def architecture_support?
        !@default_architecture.nil?
      end
    end
  end
end
