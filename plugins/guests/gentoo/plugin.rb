require "vagrant"

module VagrantPlugins
  module GuestGentoo
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Gentoo guest"
      description "Gentoo guest support."

      guest("gentoo") { Guest }
    end
  end
end
