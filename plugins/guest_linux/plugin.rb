require "vagrant"

module VagrantPlugins
  module GuestLinux
    autoload :Config, File.expand_path("../config", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Linux guest."
      description "Linux guest support."
      config("linux") { Config }
    end
  end
end
