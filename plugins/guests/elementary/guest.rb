require_relative '../linux/guest'

module VagrantPlugins
  module GuestElementary
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "elementary".freeze
    end
  end
end
