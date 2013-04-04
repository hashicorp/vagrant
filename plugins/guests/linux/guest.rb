require "vagrant"

module VagrantPlugins
  module GuestLinux
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        # TODO: Linux detection
        false
      end
    end
  end
end
