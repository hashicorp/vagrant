require "vagrant"

module VagrantPlugins
  module HostBSD
    class Plugin < Vagrant.plugin("2")
      name "BSD host"
      description "BSD host support."

      host("bsd") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
