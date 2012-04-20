require "vagrant"

module VagrantPlugins
  module HostLinux
    autoload :Host, File.expand_path("../host", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Linux host"
      description "Linux host support."

      host("linux") { Host }
    end
  end
end
