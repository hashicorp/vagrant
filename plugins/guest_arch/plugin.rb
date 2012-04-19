require "vagrant"

module VagrantPlugins
  module GuestArch
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Arch guest"
      description "Arch guest support."

      guest("arch") { Guest }
    end
  end
end
