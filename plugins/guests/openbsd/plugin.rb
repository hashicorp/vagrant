require "vagrant"

module VagrantPlugins
  module GuestOpenBSD
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "OpenBSD guest"
      description "OpenBSD guest support."

      guest("openbsd") { Guest }
    end
  end
end
