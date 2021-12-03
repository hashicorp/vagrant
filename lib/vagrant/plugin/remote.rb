require "log4r"

module Vagrant
  module Plugin
    module Remote
      autoload :Plugin, "vagrant/plugin/remote/plugin"
      autoload :SyncedFolder, "vagrant/plugin/remote/synced_folder"
    end
  end
end
