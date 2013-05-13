require "vagrant"

module VagrantPlugins
  module HostWindows
    class Plugin < Vagrant.plugin("2")
      name "Windows host"
      description "Windows host support."

      host("windows") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
