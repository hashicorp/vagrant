require "vagrant"

module VagrantPlugins
  module HostFedora
    autoload :Host, File.expand_path("../host", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Fedora host"
      description "Fedora host support."

      host("fedora") { Host }
    end
  end
end
