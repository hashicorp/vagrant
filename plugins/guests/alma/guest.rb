require_relative "../linux/guest"

module VagrantPlugins
  module GuestAlma
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "almalinux".freeze
    end
  end
end
