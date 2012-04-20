require "vagrant"

module VagrantPlugins
  module GuestDebian
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Debian guest"
      description "Debian guest support."

      guest("debian") { Guest }
    end
  end
end
