require "vagrant"

module VagrantPlugins
  module HostBSD
    autoload :Host, File.expand_path("../host", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "BSD host"
      description "BSD host support."

      host("bsd") { Host }
    end
  end
end
