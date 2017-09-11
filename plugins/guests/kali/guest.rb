require_relative '../linux/guest'

module VagrantPlugins
  module GuestKali
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "kali".freeze
    end
  end
end
