# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestOpenWrt
    class Guest < Vagrant.plugin("2", :guest)
      # Name used for guest detection
      GUEST_DETECTION_NAME = "openwrt".freeze

      def detect?(machine)
        machine.communicate.test <<~EOH
          if test -e /etc/openwrt_release; then
            exit
          fi
          if test -r /etc/os-release; then
            source /etc/os-release && test 'x#{self.class.const_get(:GUEST_DETECTION_NAME)}' = "x$ID" && exit
          fi
          if test -r /etc/banner; then
            cat /etc/banner | grep -qi '#{self.class.const_get(:GUEST_DETECTION_NAME)}' && exit
          fi
          exit 1
        EOH
      end
    end
  end
end
