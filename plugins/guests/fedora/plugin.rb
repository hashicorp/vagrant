require "vagrant"

module VagrantPlugins
  module GuestFedora
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Fedora guest"
      description "Fedora guest support."

      guest("fedora") { Guest }
    end
  end
end
