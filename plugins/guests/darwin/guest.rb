require 'vagrant/util/template_renderer'

module VagrantPlugins
  module GuestDarwin
    # A general Vagrant system implementation for "freebsd".
    #
    # Contributed by Kenneth Vestergaard <kvs@binarysolutions.dk>
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep 'Darwin'")
      end
    end
  end
end
