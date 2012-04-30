require "vagrant"

module VagrantPlugins
  module HostGentoo
    autoload :Host, File.expand_path("../host", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Gentoo host"
      description "Gentoo host support."

      host("gentoo") { Host }
    end
  end
end
