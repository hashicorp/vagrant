require "log4r"

module Vagrant
  module Plugin
    module Remote
      autoload :Communicator, "vagrant/plugin/remote/communicator"
      autoload :Manager, "vagrant/plugin/remote/manager"
      autoload :Plugin, "vagrant/plugin/remote/plugin"
      autoload :SyncedFolder, "vagrant/plugin/remote/synced_folder"
    end
  end
end
