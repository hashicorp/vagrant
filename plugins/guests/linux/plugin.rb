require "vagrant"

module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      name "Linux guest."
      description "Linux guest support."

      config("linux") do
        require File.expand_path("../config", __FILE__)
        Config
      end

      guest("linux")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
