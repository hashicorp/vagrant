require "vagrant"

module VagrantPlugins
  module HostFedora
    class Plugin < Vagrant.plugin("1")
      name "Fedora host"
      description "Fedora host support."

      host("fedora") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
