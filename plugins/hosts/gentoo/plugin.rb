require "vagrant"

module VagrantPlugins
  module HostGentoo
    class Plugin < Vagrant.plugin("2")
      name "Gentoo host"
      description "Gentoo host support."

      host("gentoo") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
