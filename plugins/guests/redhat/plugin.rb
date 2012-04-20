require "vagrant"

module VagrantPlugins
  module GuestRedHat
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "RedHat guest"
      description "RedHat guest support."

      guest("redhat") { Guest }
    end
  end
end
