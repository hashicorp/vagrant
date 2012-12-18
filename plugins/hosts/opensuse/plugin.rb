require "vagrant"

module VagrantPlugins
  module HostOpenSUSE
    class Plugin < Vagrant.plugin("2")
      name "OpenSUSE host"
      description "OpenSUSE host support."

      host("opensuse") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
