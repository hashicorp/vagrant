require "vagrant"

module VagrantPlugins
  module HostArch
    autoload :Host, File.expand_path("../host", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Arch host"
      description "Arch host support."

      host("arch") { Host }
    end
  end
end
