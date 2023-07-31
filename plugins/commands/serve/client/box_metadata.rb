# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class BoxMetadata < Client
        def name
          client.box_name(Empty.new).name
        end

        # @param [String] url for the metadata
        def load_metadata(url)
          client.load_metadata(SDK::BoxMetadata::LoadMetadataRequest.new(
            url: url
          ))
        end

        # @param [String] version The version to return, this can also
        #   be a constraint.
        # @param [Array<String>] (optional) adds a provider constraint to the version 
        def version(version, provider=[])
          opts = []
          provider.each do |p|
            opts << SDK::BoxMetadata::BoxMetadataOpts.new(name: p)
          end

          v = client.version(SDK::BoxMetadata::VersionQuery.new(
            version: version, opts: opts,
          ))
          v.to_h
        end

        # @param [String] (optional) adds a provider constraint to the version list
        def list_versions(provider)
          v = client.list_versions(SDK::BoxMetadata::ListVersionsQuery.new(
            opts: [SDK::BoxMetadata::BoxMetadataOpts.new(name: provider)],
          ))
          v.versions
        end

        def provider(version, name)
          p = client.provider(SDK::BoxMetadata::ProviderRequest.new(
            version: version, name: name
          ))
          p.to_h
        end

        def list_providers(version)
          p = client.list_providers(SDK::BoxMetadata::ListProvidersRequest.new(
            version: version
          ))
          p.providers
        end
      end
    end
  end
end
