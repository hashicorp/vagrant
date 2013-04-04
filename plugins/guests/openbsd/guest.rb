require "vagrant"

module VagrantPlugins
  module GuestOpenBSD
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        # TODO: OpenBSD detection
        false
      end
    end
  end
end
