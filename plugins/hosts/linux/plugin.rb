require "vagrant"

module VagrantPlugins
  module HostLinux
    class Plugin < Vagrant.plugin("1")
      name "Linux host"
      description "Linux host support."

      host("linux") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
