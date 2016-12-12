require_relative '../linux/guest'

module VagrantPlugins
  module GuestDebian
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "debian".freeze
    end
  end
end
