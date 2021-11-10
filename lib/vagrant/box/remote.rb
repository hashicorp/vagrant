module Vagrant
  class Box
    # This module enables the Box for server mode
    module Remote

      # Add an attribute reader for the client
      # when applied to the Box class
      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      # This is used to initialize a box.
      #
      # @param [String] name Logical name of the box.
      # @param [Symbol] provider The provider that this box implements.
      # @param [Pathname] directory The directory where this box exists on
      #   disk.
      # @param [String] metadata_url Metadata URL for box
      # @param [Hook] hook A hook to apply to the box downloader, for example, for authentication
      def initialize(name, provider, version, directory, metadata_url: nil, hook: nil)
        @logger = Log4r::Logger.new("vagrant::box")

        @name      = name
        @version   = version
        @provider  = provider
        @directory = directory
        @metadata_url = metadata_url
        @hook = hook
      end

      def destroy!
        client.destroy
      end

      def in_use?(index)
        client.in_use(index.to_proto)
      end

      def has_update?(version=nil, **opts)
        client.has_update(version)
      end

      def automatic_update_check_allowed?
        client.automatic_update_check_allowed
      end

      def repackage(path)
        client.repackage(path)
      end

      def <=>(other)
        client.compare(other.to_proto)
      end

      def to_proto
        client.proto
      end

      def client=(c)
        @client = c
      end
    end
  end
end
