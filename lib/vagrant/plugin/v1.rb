require "log4r"

require "vagrant/plugin/v1/errors"

module Vagrant
  module Plugin
    module V1
      autoload :Command, "vagrant/plugin/v1/command"
      autoload :Communicator, "vagrant/plugin/v1/communicator"
      autoload :Config, "vagrant/plugin/v1/config"
      autoload :Guest,  "vagrant/plugin/v1/guest"
      autoload :Host,   "vagrant/plugin/v1/host"
      autoload :Manager, "vagrant/plugin/v1/manager"
      autoload :Plugin, "vagrant/plugin/v1/plugin"
      autoload :Provider, "vagrant/plugin/v1/provider"
      autoload :Provisioner, "vagrant/plugin/v1/provisioner"
    end
  end
end
