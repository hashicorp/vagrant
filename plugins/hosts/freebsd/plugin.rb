require "vagrant"

module VagrantPlugins
  module HostFreeBSD
    autoload :Host, File.expand_path("../host", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "FreeBSD host"
      description "FreeBSD host support."

      host("freebsd") { Host }
    end
  end
end
