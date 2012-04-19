require "vagrant"

module VagrantPlugins
  module GuestFreeBSD
    autoload :Config, File.expand_path("../config", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "FreeBSD guest"
      description "FreeBSD guest support."
      config("freebsd") { Config }
    end
  end
end
