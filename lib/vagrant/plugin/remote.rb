# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "log4r"

module Vagrant
  module Plugin
    module Remote
      autoload :Command, "vagrant/plugin/remote/command"
      autoload :Communicator, "vagrant/plugin/remote/communicator"
      autoload :Guest, "vagrant/plugin/remote/guest"
      autoload :Manager, "vagrant/plugin/remote/manager"
      autoload :Plugin, "vagrant/plugin/remote/plugin"
      autoload :Provider, "vagrant/plugin/remote/provider"
      autoload :Push, "vagrant/plugin/remote/push"
      autoload :Provisioner, "vagrant/plugin/remote/provisioner"
      autoload :SyncedFolder, "vagrant/plugin/remote/synced_folder"
    end
  end
end
