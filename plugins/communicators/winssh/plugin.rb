require "vagrant"

module VagrantPlugins
  module CommunicatorWinSSH
    class Plugin < Vagrant.plugin("2")
      name "windows ssh communicator"
      description <<-DESC
      DESC

      communicator("winssh") do
        require File.expand_path("../communicator", __FILE__)
        Communicator
      end

      config("winssh") do
        require_relative "config"
        Config
      end
    end
  end
end
