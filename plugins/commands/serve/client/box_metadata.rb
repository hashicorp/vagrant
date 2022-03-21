module VagrantPlugins
  module CommandServe
    class Client
      class BoxMetadata < Client
        def name
          client.name(Empty.new)
        end

        # @param [String] version The version to return, this can also
        #   be a constraint.
        # @param [String] (optional) adds a provider constraint to the version 
        def version(version, provider)
          v = client.version(SDK::BoxMetadata::VersionRequest.new(
            version: version,
            opts: SDK::BoxMetadata::BoxMetadataOpts.new(name: provider)
          ))
          v.to_h
        end

        # @param [String] (optional) adds a provider constraint to the version list
        def list_versions(provider)
          v = client.list_version(SDK::BoxMetadata::BoxMetadataOpts.new(
            name: provider
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
