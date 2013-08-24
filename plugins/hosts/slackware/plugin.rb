require "vagrant"

module VagrantPlugins
  module HostSlackware
    class Plugin < Vagrant.plugin("2")
      name "Slackware host"
      description "Slackware and derivertives host support."

      host("slackware") do
        require File.expand_path("../host", __FILE__)
        Host
      end
    end
  end
end
