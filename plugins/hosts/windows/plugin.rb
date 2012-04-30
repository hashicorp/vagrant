require "vagrant"

module VagrantPlugins
  module HostWindows
    autoload :Host, File.expand_path("../host", __FILE__)

    class Plugin < Vagrant.plugin("1")
      name "Windows host"
      description "Windows host support."

      host("windows") { Host }
    end
  end
end
