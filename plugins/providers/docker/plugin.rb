module VagrantPlugins
  module DockerProvider
    class Plugin < Vagrant.plugin("2")
      name "docker-provider"

      provider(:docker, parallel: true) do
        require_relative 'provider'
        init!
        Provider
      end

      config(:docker, :provider) do
        require_relative 'config'
        init!
        Config
      end

      synced_folder(:docker) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/providers_docker.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
