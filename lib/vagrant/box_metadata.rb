require "json"

module Vagrant
  # BoxMetadata represents metadata about a box, including the name
  # it should have, a description of it, the versions it has, and
  # more.
  class BoxMetadata
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
    def initialize(io)
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
        [Gem::Version.new(v["version"]), v]
      end
      @version_map = Hash[@version_map]

      # TODO: check for corruption:
      #   - malformed version
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

      @version_map.keys.sort.reverse.each do |v|
        next if !requirements.all? { |r| r.satisfied_by?(v) }
        version = Version.new(@version_map[v])
        next if (providers & version.providers).empty? if providers
        return version
      end

      nil
    end

    # Returns all the versions supported by this metadata. These
    # versions are sorted so the last element of the list is the
    # latest version.
    #
    # @return[Array<String>]
    def versions
      @version_map.keys.sort.map(&:to_s)
    end

    # Represents a single version within the metadata.
    class Version
      # The version that this Version object represents.
      #
      # @return [String]
      attr_accessor :version

      def initialize(raw=nil)
        return if !raw

        @version = raw["version"]
        @provider_map = (raw["providers"] || []).map do |p|
          [p["name"].to_sym, p]
        end
        @provider_map = Hash[@provider_map]
      end

      # Returns a [Provider] for the given name, or nil if it isn't
      # supported by this version.
      def provider(name)
        p = @provider_map[name.to_sym]
        return nil if !p
        Provider.new(p)
      end

      # Returns the providers that are available for this version
      # of the box.
      #
      # @return [Array<Symbol>]
      def providers
        @provider_map.keys.map(&:to_sym)
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

      def initialize(raw)
        @name = raw["name"]
        @url  = raw["url"]
      end
    end
  end
end
