require "vagrant"

module VagrantPlugins
  module GuestUbuntu
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Ubuntu guest"
      description "Ubuntu guest support."

      guest("ubuntu") { Guest }
    end
  end
end
