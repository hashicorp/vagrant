I18n.load_path << File.expand_path(File.dirname(__FILE__) + '/../../locales/en.yml')
I18n.reload!

module VagrantPlugins
  module DockerProvider
    class Plugin < Vagrant.plugin("2")
      name "docker-provider"

      provider(:docker, parallel: true) do
        require_relative 'provider'
        Provider
      end

      config(:docker, :provider) do
        require_relative 'config'
        Config
      end

      synced_folder(:docker) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end
    end
  end
end
