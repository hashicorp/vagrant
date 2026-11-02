# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../linux/guest"

module VagrantPlugins
  module GuestRocky
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "rocky".freeze
    end
  end
end
