require "vagrant"

module VagrantPlugins
  module CommunicatorSSH
    class Plugin < Vagrant.plugin("2")
      name "ssh communicator"
      description <<-DESC
      This plugin allows Vagrant to communicate with remote machines using
      SSH as the underlying protocol, powered internally by Ruby's
      net-ssh library.
      DESC

      communicator("ssh") do
        require File.expand_path("../communicator", __FILE__)
        Communicator
      end
    end
  end
end
