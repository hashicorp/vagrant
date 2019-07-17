begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant Alpine Linux Guest plugin must be run within Vagrant.'
end

if Vagrant::VERSION < '1.7.0'
  fail 'The vagrant-alpine plugin is only compatible with Vagrant 1.7+'
end

module VagrantPlugins
  module GuestAlpine
    class Guest < Vagrant.plugin('2', :guest)
      def detect?(machine)
        machine.communicate.test('cat /etc/alpine-release')
      end
    end
  end
end
