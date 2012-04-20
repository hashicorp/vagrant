require "vagrant"

module VagrantPlugins
  module GuestSolaris
    autoload :Config, File.expand_path("../config", __FILE__)
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Solaris guest."
      description "Solaris guest support."

      config("solaris") { Config }
      guest("solaris")  { Guest }
    end
  end
end
