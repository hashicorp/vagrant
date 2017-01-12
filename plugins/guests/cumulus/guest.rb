require_relative '../linux/guest'

module VagrantPlugins
  module GuestCumulus
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "cumulus".freeze
    end
  end
end
