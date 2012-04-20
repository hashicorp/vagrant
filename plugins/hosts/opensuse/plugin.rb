require "vagrant"

module VagrantPlugins
  module HostOpenSUSE
    autoload :Host, File.expand_path("../host", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "OpenSUSE host"
      description "OpenSUSE host support."

      host("opensuse") { Host }
    end
  end
end
