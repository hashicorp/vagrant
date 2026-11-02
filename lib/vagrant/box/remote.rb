# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
      def initialize(name, provider, version, directory, metadata_url: nil, hook: nil, client: nil)
        @logger = Log4r::Logger.new("vagrant::box")

        @name      = name
        @version   = version
        @provider  = provider
        @directory = directory
        @metadata_url = metadata_url
        @hook = hook

        if client.nil?
          raise ArgumentError,
            "Remote client is required for `#{self.class.name}'"
        end
        @client = client
        @metadata = client.box_metadata
      end

      def destroy!
        client.destroy
      end

      def in_use?(index)
        client.machines(index.to_proto)
      end

      def has_update?(version=nil, **opts)
        update_info = client.update_info(version)
        if update_info.nil?
          return nil
        end
        metadata = update_info[0]
        new_version = update_info[1]
        new_provider = update_info[2]
        [
          BoxMetadata.new(nil, client: metadata),
          BoxMetadata::Version.new({"version" => new_version}, ver: new_version, client: metadata), 
          BoxMetadata::Provider.new({"name" => new_provider}, client: metadata),
        ]
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
    end
  end
end
