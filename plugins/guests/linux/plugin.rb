require "vagrant"

module VagrantPlugins
  module GuestLinux
    autoload :Config, File.expand_path("../config", __FILE__)
    autoload :Guest, File.expand_path("../guest", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Linux guest."
      description "Linux guest support."

      config("linux") { Config }
      guest("linux")  { Guest }
    end
  end
end
