require "vagrant"

module VagrantPlugins
  module GuestCygwin
    class Plugin < Vagrant.plugin("2")
      name "Cygwin guest."
      description "Cygwin on Windows guest support."

      config("cygwin") do
        require File.expand_path("../config", __FILE__)
        Config
      end

      guest("cygwin")  do
        require File.expand_path("../guest", __FILE__)
        Guest
      end
    end
  end
end
