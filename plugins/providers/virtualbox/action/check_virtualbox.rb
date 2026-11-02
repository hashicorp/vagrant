# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require 'vagrant/util/platform'

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # Checks that VirtualBox is installed and ready to be used.
      class CheckVirtualbox
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::provider::virtualbox")
        end

        def call(env)
          # This verifies that VirtualBox is installed and the driver is
          # ready to function. If not, then an exception will be raised
          # which will break us out of execution of the middleware sequence.
          Driver::Meta.new.verify!

          # Carry on.
          @app.call(env)
        end
      end
    end
  end
end
