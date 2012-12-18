require "vagrant"

module VagrantPlugins
  module HostArch
    class Plugin < Vagrant.plugin("2")
      name "Arch host"
      description "Arch host support."

      host("arch") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
