require "vagrant"

module VagrantPlugins
  module GuestFreeBSD
    autoload :Config, File.expand_path("../config", __FILE__)
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "FreeBSD guest"
      description "FreeBSD guest support."

      config("freebsd") { Config }
      guest("freebsd")  { Guest }
    end
  end
end
