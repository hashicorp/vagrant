# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Action
    # A PrimaryRunner is a special kind of "top-level" Action::Runner - it
    # informs any Action::Builders it interacts with that they are also
    # primary. This allows Builders to distinguish whether or not they are
    # nested, which they need to know for proper action_hook handling.
    #
    # @see Vagrant::Action::Builder#primary
    class PrimaryRunner < Runner
      def primary?
        true
      end
    end
  end
end
