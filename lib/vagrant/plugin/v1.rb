require "log4r"

require "vagrant/plugin/v1/errors"

module Vagrant
  module Plugin
    module V1
      autoload :Config, "vagrant/plugin/v1/config"
      autoload :Plugin, "vagrant/plugin/v1/plugin"
    end
  end
end
