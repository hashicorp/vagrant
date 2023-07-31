# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Plugin
    module Remote
      # This is the wrapper class for all Remote plugins.
      class Plugin < Vagrant::Plugin::V2::Plugin

        # The logger for this class.
        LOGGER = Log4r::Logger.new("vagrant::plugin::remote::plugin")

        # Set the root class up to be ourself, so that we can reference this
        # from within methods which are probably in subclasses.
        ROOT_CLASS = self

        # This returns the manager for all Remote plugins.
        #
        # @return [Remote::Manager]
        def self.manager
          LOGGER.debug("Returning remote manager from plugin")
          @manager ||= Vagrant::Plugin::Remote::Manager.new
        end
      end
    end
  end
end
