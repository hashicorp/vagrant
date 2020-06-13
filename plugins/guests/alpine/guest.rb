require 'vagrant'

module VagrantPlugins
  module GuestAlpine
    class Guest < Vagrant.plugin('2', :guest)
      def detect?(machine)
        machine.communicate.test('cat /etc/alpine-release')
      end
    end
  end
end
