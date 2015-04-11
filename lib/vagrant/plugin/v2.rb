require "log4r"

# We don't autoload components because if we're loading anything in the
# V2 namespace anyways, then we're going to need the Components class.
require "vagrant/plugin/v2/components"
require "vagrant/plugin/v2/errors"

module Vagrant
  module Plugin
    module V2
      autoload :Command, "vagrant/plugin/v2/command"
      autoload :Communicator, "vagrant/plugin/v2/communicator"
      autoload :Config, "vagrant/plugin/v2/config"
      autoload :Guest,  "vagrant/plugin/v2/guest"
      autoload :Host,   "vagrant/plugin/v2/host"
      autoload :Manager, "vagrant/plugin/v2/manager"
      autoload :Plugin, "vagrant/plugin/v2/plugin"
      autoload :Provider, "vagrant/plugin/v2/provider"
      autoload :Push, "vagrant/plugin/v2/push"
      autoload :Provisioner, "vagrant/plugin/v2/provisioner"
      autoload :SyncedFolder, "vagrant/plugin/v2/synced_folder"
    end
  end
end
