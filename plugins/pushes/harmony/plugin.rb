require "vagrant"

module VagrantPlugins
  module HarmonyPush
    class Plugin < Vagrant.plugin("2")
      name "harmony"
      description <<-DESC
      Deploy using HashiCorp's Harmony service.
      DESC

      config(:harmony, :push) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      push(:harmony) do
        require File.expand_path("../push", __FILE__)
        Push
      end
    end
  end
end
