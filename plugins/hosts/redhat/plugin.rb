require "vagrant"

module VagrantPlugins
  module HostRedHat
    class Plugin < Vagrant.plugin("2")
      name "Red Hat host"
      description "Red Hat host support."

      host("redhat") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
