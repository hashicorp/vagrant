require "vagrant"

module VagrantPlugins
  module NoopDeploy
    class Plugin < Vagrant.plugin("2")
      name "noop"
      description <<-DESC
      Literally do nothing
      DESC

      config(:noop, :push) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      push(:noop) do
        require File.expand_path("../push", __FILE__)
        Push
      end
    end
  end
end
