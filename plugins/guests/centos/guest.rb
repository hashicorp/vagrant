# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant"
require_relative '../linux/guest'

module VagrantPlugins
  module GuestCentos
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "centos".freeze
    end
  end
end
