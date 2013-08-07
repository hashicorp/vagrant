require 'vagrant/util/template_renderer'

module VagrantPlugins
  module GuestDarwin
    # A general Vagrant system implementation for OS X (ie. "Darwin").
    #
    # Contributed by: - Brian Johnson <b2jrock@gmail.com>
    #                 - Tim Sutton <tim@synthist.net>
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep 'Darwin'")
      end
    end
  end
end
