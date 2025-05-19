require_relative "../linux/guest"

module VagrantPlugins
  module GuestUos
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "uos".freeze
    end
  end
end
