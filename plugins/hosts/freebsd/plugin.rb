require "vagrant"

module VagrantPlugins
  module HostFreeBSD
    class Plugin < Vagrant.plugin("2")
      name "FreeBSD host"
      description "FreeBSD host support."

      host("freebsd") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
