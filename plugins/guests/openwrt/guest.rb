require_relative '../linux/guest'

module VagrantPlugins
  module GuestOpenWrt
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "openwrt".freeze
    end
  end
end
