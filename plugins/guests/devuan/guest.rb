require_relative '../linux/guest'

module VagrantPlugins
  module GuestDevuan
    class Guest < VagrantPlugins::GuestLinux::Guest
      # Name used for guest detection
      GUEST_DETECTION_NAME = "devuan".freeze
    end
  end
end
