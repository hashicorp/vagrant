require "vagrant"

module VagrantPlugins
  module HostSolaris
    class Plugin < Vagrant.plugin("2")
      name "Solaris host"
      description "Solaris and derivertives host support."

      host("solaris") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
