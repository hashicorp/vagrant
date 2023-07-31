# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Util
    module Remote
      module SafePuts
        # The SafePuts module is included in a few different places to
        # provide a safe_puts method which does not error in the case that
        # stdout is closed.
        #
        # When we are in remote mode, stdout is in fact closed as all I/O
        # is happening over an RPC interface. Instead of having safe_puts
        # just swallow output every time it's called, we want it to send
        # the message somewhere it will eventually be output.
        #
        # To do this, we need to do some reflection to figure out what gets us
        # to a UI::Remote.
        def safe_puts(message=nil, opts=nil)
          # When we're in a Command context, we can get a UI::Remote from the
          # Environment
          if instance_variable_defined?(:@env)
            @env.ui.output(message)
          else
            raise "Cannot safe_puts in remote mode from #{self.class}; Remote::SafePuts must be updated to handle this context"
          end
        end
      end
    end
  end
end
