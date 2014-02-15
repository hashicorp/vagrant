module VagrantPlugins
  module HyperV
    class Plugin < Vagrant.plugin("2")
      name "Hyper-V provider"
      description <<-DESC
      This plugin installs a provider that allows Vagrant to manage
      machines in Hyper-V.
      DESC

      provider(:hyperv, parallel: true) do
        require_relative "provider"
        Provider
      end

      config(:hyperv, :provider) do
        require_relative "config"
        Config
      end
    end
  end
end
