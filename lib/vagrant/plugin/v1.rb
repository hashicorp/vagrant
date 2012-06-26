require "log4r"

require "vagrant/plugin/v1/errors"

module Vagrant
  module Plugin
    module V1
      autoload :Command, "vagrant/plugin/v1/command"
      autoload :Config, "vagrant/plugin/v1/config"
      autoload :Guest,  "vagrant/plugin/v1/guest"
      autoload :Plugin, "vagrant/plugin/v1/plugin"
      autoload :Provisioner, "vagrant/plugin/v1/provisioner"
    end
  end
end
