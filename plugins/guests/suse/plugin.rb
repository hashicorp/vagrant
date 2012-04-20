require "vagrant"

module VagrantPlugins
  module GuestSuse
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "SUSE guest"
      description "SUSE guest support."

      guest("suse") { Guest }
    end
  end
end
